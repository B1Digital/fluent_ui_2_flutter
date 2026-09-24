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

        // One more across than Figma: upstream keeps a 1px border on every
        // appearance and a CSS border takes layout space, where a Figma stroke
        // sits inside the frame without moving the content. Vertically Figma's
        // number already includes it.
        expect(
          padding.left,
          variant.padding!.left + FluentStroke.thin,
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

  // Numbers the Figma fixture cannot state: its frames hug their contents and
  // its Large icon slot is an instance rather than a token. They come from
  // `react-button/library/src/components/Button/useButtonStyles.styles.ts` and
  // were confirmed against a live probe of the React storybook.
  group('geometry Figma cannot express', () {
    testWidgets('a labelled button is floored at upstream\'s minWidth', (
      tester,
    ) async {
      // `useButtonStyles.styles.ts`: `minWidth: '96px'` on the base and on
      // large, `'64px'` on small. A live probe renders a text-only Medium at
      // exactly 96x32, and a split button's primary half — a Button — at 96.
      const floors = <FluentButtonSize, double>{
        FluentButtonSize.small: 64,
        FluentButtonSize.medium: 96,
        FluentButtonSize.large: 96,
      };

      for (final entry in floors.entries) {
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
          entry.value,
          reason: '${entry.key.name}: a short label is padded out to the floor',
        );
      }
    });

    testWidgets('an icon-only button is a square at the button height', (
      tester,
    ) async {
      // `useRootIconOnlyStyles` replaces the floor with `minWidth == maxWidth
      // == 24/32/40` and pads by 1, 5 or 7 — which with the 1px border lands
      // the 20 (24 at large) glyph exactly on that square.
      const squares = <FluentButtonSize, double>{
        FluentButtonSize.small: 24,
        FluentButtonSize.medium: 32,
        FluentButtonSize.large: 40,
      };

      for (final entry in squares.entries) {
        await pump(
          tester,
          FluentButton.icon(
            key: key,
            size: entry.key,
            icon: const Icon(FluentIcons.add_20_regular),
            semanticLabel: 'Add',
            onPressed: () {},
          ),
        );
        expect(
          tester.getSize(find.byKey(key)),
          Size.square(entry.value),
          reason: entry.key.name,
        );
      }
    });

    test('a selected outline button grows by its thicker border', () {
      // An open outline MenuButton or a checked outline ToggleButton takes a
      // 3px border, which takes layout space as the 1px one does: Chrome
      // renders the checked outline toggle 36 high against 32 unchecked.
      final style = resolveFluentButtonStyle(
        resolveFluentButtonState(appearance: FluentButtonAppearance.outline),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      const selected = <WidgetState>{WidgetState.selected};
      expect(style.borderWidth!.resolve(selected), FluentStroke.thicker);
      expect(
        style.padding!.resolve(selected),
        style.padding!
            .resolve(const <WidgetState>{})!
            .add(
              const EdgeInsets.all(FluentStroke.thicker - FluentStroke.thin),
            ),
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

  // `useButtonStyles`' `createCustomFocusIndicatorStyle`, and a live probe of
  // the Button and SplitButton stories with keyboard focus.
  group('focus, as upstream draws it', () {
    FluentThemeData light() =>
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    /// Focuses [node] and flips the modality to keyboard, which is what raises
    /// a Fluent ring: Escape moves no focus, so the same node re-evaluates.
    Future<void> keyboardFocus(WidgetTester tester, FocusNode node) async {
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }

    FluentFocusRingPainter ringOf(WidgetTester tester) => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.foregroundPainter)
        .whereType<FluentFocusRingPainter>()
        .single;

    testWidgets('the ring sits inside the button, 2px deep', (tester) async {
      // The border turned `strokeFocus2` plus a 1px inset shadow of it: the
      // probe reads 8 device pixels of black from the edge at DPR 4, and
      // nothing outside the button.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentButton(
          key: key,
          focusNode: node,
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      await keyboardFocus(tester, node);

      final ring = ringOf(tester);
      expect(ring.visible, isTrue);
      expect(ring.insets, const EdgeInsets.all(FluentStroke.thick));
      expect(ring.innerWidth, FluentStroke.none);
      expect(
        decorationOf(tester).border!.top.color,
        light().colors.strokeFocus2,
      );
    });

    testWidgets('a focused rounded button takes its size\'s radius', (
      tester,
    ) async {
      // `useRootFocusStyles`: small borderRadiusSmall, large borderRadiusLarge;
      // circular and square keep their own.
      const radii = <FluentButtonSize, BorderRadius>{
        FluentButtonSize.small: FluentRadius.allSmall,
        FluentButtonSize.medium: FluentRadius.allMedium,
        FluentButtonSize.large: FluentRadius.allLarge,
      };
      for (final entry in radii.entries) {
        final node = FocusNode();
        addTearDown(node.dispose);
        // A fresh tree, so the last iteration's focused node goes with it.
        await tester.pumpWidget(const SizedBox());
        await pump(
          tester,
          FluentButton(
            key: key,
            size: entry.key,
            focusNode: node,
            onPressed: () {},
            child: const Text('Button'),
          ),
        );
        expect(decorationOf(tester).borderRadius, FluentRadius.allMedium);
        await keyboardFocus(tester, node);
        expect(
          decorationOf(tester).borderRadius,
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    testWidgets('primary adds a white ring and a shadow, and hover drops the '
        'ring', (tester) async {
      // `useRootFocusStyles.primary`: `shadow2`, 1px `strokeFocus2` inset over
      // 2px `colorNeutralForegroundOnBrand` inset — and under `:hover` only
      // `shadow2` and the black.
      final theme = light();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentButton(
          key: key,
          appearance: FluentButtonAppearance.primary,
          focusNode: node,
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      await keyboardFocus(tester, node);

      final shadow2 = FluentElevation.shadow2.shadows(
        ambient: theme.colors.neutralShadowAmbient,
        key: theme.colors.neutralShadowKey,
      );
      expect(ringOf(tester).innerWidth, FluentStroke.thin);
      expect(ringOf(tester).inner, theme.colors.neutralForegroundOnBrand);
      expect(decorationOf(tester).boxShadow, shadow2);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(ringOf(tester).visible, isTrue, reason: 'hover keeps focus');
      expect(ringOf(tester).innerWidth, FluentStroke.none);
      expect(decorationOf(tester).boxShadow, shadow2);
    });

    testWidgets('the focus stroke outranks hover', (tester) async {
      // Probed focused and hovered: the border stays rgb(0, 0, 0).
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentButton(
          key: key,
          focusNode: node,
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      await keyboardFocus(tester, node);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester).border!.top.color,
        light().colors.strokeFocus2,
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

    testWidgets('the border and the label tween with the surface', (
      tester,
    ) async {
      // The same declaration moves `border` and `color` too: a Chrome timeline
      // of button--appearance has the edge still easing at 99ms after
      // mousedown. They used to snap on the first frame.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      Color? labelColor() => tester
          .widget<RichText>(
            find.descendant(
              of: find.text('B'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;

      for (final appearance in <FluentButtonAppearance>[
        FluentButtonAppearance.secondary,
        FluentButtonAppearance.transparent,
      ]) {
        await pump(
          tester,
          FluentButton(
            key: key,
            appearance: appearance,
            onPressed: () {},
            child: const Text('B'),
          ),
        );
        await tester.pumpAndSettle();

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await tester.pump();
        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        if (appearance == FluentButtonAppearance.secondary) {
          final edge = decorationOf(tester).border!.top.color;
          expect(edge, isNot(theme.colors.neutralStroke1));
          expect(edge, isNot(theme.colors.neutralStroke1Hover));
        } else {
          expect(labelColor(), isNot(theme.colors.neutralForeground2));
          expect(
            labelColor(),
            isNot(theme.colors.neutralForeground2BrandHover),
          );
        }

        await tester.pumpAndSettle();
        if (appearance == FluentButtonAppearance.secondary) {
          expect(
            decorationOf(tester).border!.top.color,
            theme.colors.neutralStroke1Hover,
          );
        } else {
          expect(labelColor(), theme.colors.neutralForeground2BrandHover);
        }
        await mouse.removePointer();
      }
    });
  });

  group('animationDuration', () {
    testWidgets('zero lands every colour on the frame the state changes', (
      tester,
    ) async {
      // For a control built on a button whose upstream counterpart declares no
      // transition, like the carousel's step (`CarouselNavButton`: `all 0s`).
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentButton(
          key: key,
          style: const FluentButtonStyle(animationDuration: Duration.zero),
          onPressed: () {},
          child: const Text('B'),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      await mouse.moveTo(
        tester.getCenter(find.byKey(key)) + const Offset(1, 0),
      );
      await tester.pump();
      expect(decorationOf(tester).color, theme.colors.neutralBackground1Hover);
      expect(
        decorationOf(tester).border!.top.color,
        theme.colors.neutralStroke1Hover,
      );
    });
  });

  group('hover and press, as the storybook renders them', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    Color? iconColorOf(WidgetTester tester) => tester
        .widget<RichText>(
          find.descendant(
            of: find.byType(Icon),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color;

    Future<TestGesture> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      // Drift a pixel, as a real pointer does after it arrives.
      await mouse.moveTo(
        tester.getCenter(find.byKey(key)) + const Offset(1, 0),
      );
      await tester.pumpAndSettle();
      return mouse;
    }

    Color? glyphColor(WidgetTester tester, IconData icon) => tester
        .widget<RichText>(
          find.descendant(
            of: find.byIcon(icon),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style
        ?.color;

    testWidgets('a menu icon sits 4 after the label, 12 or 16 square, and '
        'keeps the label colour', (tester) async {
      // menubutton--appearance and --size in Chrome: `.fui-MenuButton__menuIcon`
      // is 12x12 (16x16 at large) with `margin-left: 4px`, and on a hovered
      // Subtle MenuButton it stays the label's rgb(36,36,36) while the icon
      // before the label goes brand rgb(15,108,189). It used to be the
      // button's 20px icon slot, 6 from the label, and brand with the icon.
      const chevron = FluentIcons.chevron_down_20_regular;
      for (final size in FluentButtonSize.values) {
        await pump(
          tester,
          FluentButton(
            key: key,
            size: size,
            appearance: FluentButtonAppearance.subtle,
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            menuIcon: fluentMenuChevron,
            onPressed: () {},
            child: const Text('B'),
          ),
        );
        await tester.pumpAndSettle();
        final edge = size == FluentButtonSize.large ? 16.0 : 12.0;
        expect(
          tester.getSize(find.byIcon(chevron)),
          Size.square(edge),
          reason: size.name,
        );
        expect(
          tester.getTopLeft(find.byIcon(chevron)).dx -
              tester.getTopRight(find.text('B')).dx,
          FluentSpacing.xs,
          reason: '${size.name}: gap after the label',
        );

        final mouse = await hover(tester);
        expect(
          glyphColor(tester, chevron),
          theme.colors.neutralForeground1Hover,
          reason: '${size.name}: the chevron follows the label',
        );
        expect(
          glyphColor(tester, FluentIcons.calendar_month_20_regular),
          theme.colors.neutralForeground2BrandHover,
          reason: '${size.name}: the icon goes brand',
        );
        await mouse.removePointer();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('subtle tints its icon brand while the label stays neutral', (
      tester,
    ) async {
      // button--appearance, Subtle: label rgb(36,36,36) with the icon
      // rgb(15,108,189) on hover and rgb(17,94,163) pressed —
      // `useButtonStyles.subtle` colours `.fui-Button__icon` on its own.
      await pump(
        tester,
        FluentButton(
          key: key,
          appearance: FluentButtonAppearance.subtle,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          child: const Text('B'),
        ),
      );
      await tester.pumpAndSettle();
      expect(iconColorOf(tester), theme.colors.neutralForeground2);

      final mouse = await hover(tester);
      expect(iconColorOf(tester), theme.colors.neutralForeground2BrandHover);
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.text('B'),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style
            ?.color,
        theme.colors.neutralForeground1Hover,
      );

      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(iconColorOf(tester), theme.colors.neutralForeground2BrandPressed);
      await mouse.up();
    });

    testWidgets('a resting subtle icon still follows a foreground override', (
      tester,
    ) async {
      // At rest upstream's icon inherits the label colour, so a caller's
      // foreground reaches it; only hover and press recolour it on their own.
      const ink = Color(0xFFAA0000);
      await pump(
        tester,
        FluentButton(
          key: key,
          appearance: FluentButtonAppearance.subtle,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          style: FluentButtonStyle.from(foregroundColor: ink),
          onPressed: () {},
          child: const Text('B'),
        ),
      );
      await tester.pumpAndSettle();
      expect(iconColorOf(tester), ink);
    });

    testWidgets('subtle and transparent swap in the active icon on hover', (
      tester,
    ) async {
      // bundleIcon: the Filled glyph shows under `:hover` on subtle and
      // transparent, and never on the other three appearances.
      const regular = Icon(FluentIcons.calendar_month_20_regular);
      const filled = Icon(FluentIcons.calendar_month_20_filled);
      for (final appearance in FluentButtonAppearance.values) {
        await pump(
          tester,
          FluentButton(
            key: key,
            appearance: appearance,
            icon: regular,
            activeIcon: filled,
            onPressed: () {},
            child: const Text('B'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byWidget(regular), findsOneWidget, reason: 'at rest');

        final mouse = await hover(tester);
        final swaps =
            appearance == FluentButtonAppearance.subtle ||
            appearance == FluentButtonAppearance.transparent;
        expect(
          find.byWidget(swaps ? filled : regular),
          findsOneWidget,
          reason: '${appearance.name}: hovered',
        );
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(find.byWidget(regular), findsOneWidget, reason: 'after leave');
      }
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
