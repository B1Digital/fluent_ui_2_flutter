import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentInfoButton` is the ⓘ trigger from the Figma `.Info button` set — 15
/// variants over Size and State, and the whole component is one square, one
/// glyph and four fill tokens.
///
/// Two things beyond the usual token fidelity get covered here. The **open**
/// state is a real Fluent `Selected` token rather than a visual flag, which the
/// fixture's `State=Selected (Popover open)` variants pin down. And the tip
/// surface is a plain `Overlay` entry until `FluentPopover` lands in Wave 4 —
/// so what is asserted about it is the part that will survive that move: the
/// tokens, the type ramp and the 264 wrap width, all of which upstream keeps in
/// `useInfoButtonStyles.styles.ts`.
void main() {
  const key = Key('info-button');
  const tipKey = Key('tip');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Center(child: child),
    ),
  );

  /// The trigger's own decorated surface, skipping the focus ring's CustomPaint.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  EdgeInsets paddingOf(WidgetTester tester, Finder of) => tester
      .widgetList<Padding>(
        find.descendant(of: of, matching: find.byType(Padding)),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  IconThemeData iconThemeOf(WidgetTester tester) => tester
      .widgetList<IconTheme>(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
      )
      .first
      .data;

  /// The token the fixture names for a variant's surface.
  ///
  /// `Size=Small, State=Selected (Popover open)` is the one variant that paints
  /// nothing on its own frame — the fill sits on a nested `Icon` instance
  /// instead. Same token, one level down; an authoring slip, not a different
  /// spec.
  String fillToken(SpecVariant variant) =>
      variant.token('fills') ?? variant.part('Icon').token('fills')!;

  /// The token the fixture names for a variant's glyph.
  String glyphToken(SpecVariant variant) =>
      variant.part('Shape').token('fills')!;

  Color colorFor(FluentThemeData theme, String token) => switch (token) {
    'Neutral/Background/Transparent/Rest' => theme.colors.transparentBackground,
    'Neutral/Background/Transparent/Hover' =>
      theme.colors.transparentBackgroundHover,
    'Neutral/Background/Transparent/Pressed' =>
      theme.colors.transparentBackgroundPressed,
    'Neutral/Background/Transparent/Selected' =>
      theme.colors.transparentBackgroundSelected,
    'Neutral/Foreground/2/Rest' => theme.colors.neutralForeground2,
    'Neutral/Foreground/2/Brand/Hover' =>
      theme.colors.neutralForeground2BrandHover,
    'Neutral/Foreground/2/Brand/Pressed' =>
      theme.colors.neutralForeground2BrandPressed,
    'Neutral/Foreground/2/Brand/Selected' =>
      theme.colors.neutralForeground2BrandSelected,
    final other => fail('unmapped token $other'),
  };

  FluentInfoButtonSize sizeFor(String name) => switch (name) {
    'Small' => FluentInfoButtonSize.small,
    'Medium' => FluentInfoButtonSize.medium,
    'Large' => FluentInfoButtonSize.large,
    final other => fail('unmapped Size $other'),
  };

  Set<WidgetState> statesFor(String name) => switch (name) {
    'Rest' => const <WidgetState>{},
    'Hover' => const <WidgetState>{WidgetState.hovered},
    'Pressed' => const <WidgetState>{WidgetState.pressed},
    'Selected (Popover open)' => const <WidgetState>{WidgetState.selected},
    'Focus' => const <WidgetState>{WidgetState.focused},
    final other => fail('unmapped State $other'),
  };

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('info_button');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 15);
    });

    test('Figma ships no Disabled variant, so disabled is ours', () {
      // The State axis is Rest, Hover, Pressed, Selected and Focus. The
      // disabled ramp in resolveFluentInfoButtonStyle is therefore an
      // extrapolation — called out here rather than quietly asserted against a
      // variant that does not exist.
      expect(spec.properties['State'], isNot(contains('Disabled')));
    });

    testWidgets('every variant matches its geometry, fill and glyph', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final size = sizeFor(variant.props['Size']!);
        final states = statesFor(variant.props['State']!);
        final state = resolveFluentInfoButtonState(
          size: size,
          info: const Text('Info'),
        );
        final style = resolveFluentInfoButtonStyle(state, light);

        await pump(
          tester,
          KeyedSubtree(
            key: key,
            child: buildFluentInfoButton(state, style, states),
          ),
        );

        expect(
          tester.getSize(find.byKey(key)),
          variant.size,
          reason: '${variant.name}: box',
        );
        expect(
          paddingOf(tester, find.byKey(key)),
          variant.padding,
          reason: '${variant.name}: padding',
        );
        expect(
          decorationOf(tester).borderRadius,
          variant.radius,
          reason: '${variant.name}: radius',
        );

        // The colour is selected from the token the fixture names, never
        // reverse-engineered from the hex it resolved to. Figma stores a fully
        // transparent token as #00FFFFFF and core stores CSS `transparent`
        // (#00000000), so the resolved *value* is only comparable by alpha —
        // the token identity is what carries the meaning.
        final fill = decorationOf(tester).color!;
        expect(
          fill,
          colorFor(light, fillToken(variant)),
          reason: '${variant.name}: fill (${fillToken(variant)})',
        );
        expect(fill.a, 0, reason: '${variant.name}: no state paints a surface');

        final icons = iconThemeOf(tester);
        expect(
          icons.color,
          colorFor(light, glyphToken(variant)),
          reason: '${variant.name}: glyph (${glyphToken(variant)})',
        );
        expect(
          icons.size,
          variant.part('Shape').size.width <= 10
              ? FluentSize.size120
              : variant.part('Shape').size.width <= 14
              ? FluentSize.size160
              : FluentSize.size200,
          reason: '${variant.name}: glyph box',
        );

        // Figma swaps the icon COMPONENT rather than recolouring one: the
        // `Shape` under Rest and Focus is a different node from the one under
        // Hover, Pressed and Selected. Filled is exactly the brand-foreground
        // states.
        final filled = glyphToken(variant).contains('Brand');
        expect(
          tester
              .widget<Icon>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(Icon),
                ),
              )
              .icon,
          filled
              ? fluentInfoButtonActiveIcon(size)
              : fluentInfoButtonIcon(size),
          reason: '${variant.name}: regular/filled glyph',
        );
      }
    });

    testWidgets('the Focus variant raises the ring, and only it', (
      tester,
    ) async {
      final spec = loadSpec('info_button');
      for (final variant in spec.where(const {'Size': 'Medium'})) {
        final states = statesFor(variant.props['State']!);
        final state = resolveFluentInfoButtonState(info: const Text('Info'));
        await pump(
          tester,
          KeyedSubtree(
            key: key,
            child: buildFluentInfoButton(
              state,
              resolveFluentInfoButtonStyle(state, light),
              states,
            ),
          ),
        );
        final painter = tester
            .widgetList<CustomPaint>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(CustomPaint),
              ),
            )
            .map((p) => p.foregroundPainter)
            .whereType<FluentFocusRingPainter>()
            .first;
        expect(
          painter.visible,
          variant.props['State'] == 'Focus',
          reason: variant.name,
        );
        if (!painter.visible) continue;

        // Figma strokes the variant frame 2px in Neutral/Stroke/Focus/2/Rest,
        // which is exactly the shared ring's outer stroke, on the component's
        // own Corner radius/Medium.
        expect(painter.outer, light.colors.strokeFocus2);
        expect(painter.outerWidth, variant.strokeWidth);
        expect(painter.borderRadius, variant.radius);
        // DIVERGENCE, reported rather than followed: Figma nests a `Focus
        // outline` rectangle of Neutral/Stroke/Focus/1/Rest inside the
        // Focus/2 stroke, 3px wide. React draws no inner ring on any
        // component — `createFocusOutlineStyle` never references
        // colorStrokeFocus1 — and a live probe of `.fui-InfoButton::after`
        // reads a lone `border: 2px solid rgb(0, 0, 0)` at `inset: -2px`.
        // FluentFocusRing follows React; FluentFocusRing.twoTone still draws
        // Figma's pair, and the Figma value is asserted here so a change to
        // the fixture is caught rather than silently absorbed.
        expect(painter.innerWidth, FluentStroke.none);
        expect(variant.part('Focus outline').strokeWidth, FluentStroke.thicker);
      }
    });
  });

  group('motion', () {
    testWidgets('hover is instant — upstream declares no transition', (
      tester,
    ) async {
      // Verified against useInfoButtonStyles.styles.ts and
      // useInfoLabelStyles.styles.ts on microsoft/fluentui@master: neither file
      // contains `transition`, `motionTokens`, a duration or a curve. There is
      // deliberately no FluentAnimatedStyle here for reduced motion to shorten.
      await pump(
        tester,
        const FluentInfoButton(
          key: key,
          semanticLabel: 'More information',
          info: Text('Info'),
        ),
      );
      expect(decorationOf(tester).color, light.colors.transparentBackground);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      // One frame. A tween would still be at the rest colour here.
      await tester.pump();

      expect(
        iconThemeOf(tester).color,
        light.colors.neutralForeground2BrandHover,
        reason: 'must be instant, not mid-tween',
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentAnimatedStyle<Color>),
        ),
        findsNothing,
      );
    });
  });

  group('the open state', () {
    testWidgets('tapping opens the tip and selects the trigger', (
      tester,
    ) async {
      final opened = <bool>[];
      await pump(
        tester,
        FluentInfoButton(
          key: key,
          semanticLabel: 'More information',
          onOpenChanged: opened.add,
          info: const Text('Kept for 30 days', key: tipKey),
        ),
      );
      expect(find.byKey(tipKey), findsNothing);

      await tester.tap(find.byKey(key));
      await tester.pump();

      expect(find.byKey(tipKey), findsOneWidget);
      expect(opened, <bool>[true]);
      // Selected is a real Fluent token here, not focus borrowing the slot.
      expect(
        iconThemeOf(tester).color,
        light.colors.neutralForeground2BrandSelected,
      );

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);
      expect(opened, <bool>[true, false]);
      expect(iconThemeOf(tester).color, light.colors.neutralForeground2);
    });

    testWidgets('Space opens it and Escape closes it', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentInfoButton(
          key: key,
          focusNode: node,
          semanticLabel: 'More information',
          info: const Text('Kept for 30 days', key: tipKey),
        ),
      );

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(tipKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(tipKey), findsOneWidget, reason: 'Enter opens it too');
    });

    testWidgets('a tap outside closes it, a tap on the tip does not', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentInfoButton(
          key: key,
          semanticLabel: 'More information',
          info: Text('Kept for 30 days', key: tipKey),
        ),
      );
      await tester.tap(find.byKey(key));
      await tester.pump();

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);

      await tester.tap(find.byKey(key));
      await tester.pump();
      await tester.tap(find.byKey(tipKey));
      await tester.pump();
      expect(
        find.byKey(tipKey),
        findsOneWidget,
        reason: 'the tip shares the trigger\'s tap-region group',
      );
    });

    testWidgets('disabled is a real state: it never opens', (tester) async {
      await pump(
        tester,
        const FluentInfoButton(
          key: key,
          enabled: false,
          semanticLabel: 'More information',
          info: Text('Kept for 30 days', key: tipKey),
        ),
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);
      expect(
        iconThemeOf(tester).color,
        light.colors.neutralForegroundDisabled,
        reason: 'a disabled token, not the enabled glyph at reduced opacity',
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Opacity)),
        findsNothing,
      );
    });

    testWidgets('disabling while open tears the tip down', (tester) async {
      for (final enabled in <bool>[true, false]) {
        await pump(
          tester,
          FluentInfoButton(
            key: key,
            enabled: enabled,
            semanticLabel: 'More information',
            info: const Text('Kept for 30 days', key: tipKey),
          ),
        );
        if (enabled) {
          await tester.tap(find.byKey(key));
          await tester.pump();
          expect(find.byKey(tipKey), findsOneWidget);
        }
      }
      await tester.pump();
      expect(find.byKey(tipKey), findsNothing);
    });
  });

  group('the tip surface', () {
    BoxDecoration tipDecoration(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.ancestor(
            of: find.byKey(tipKey),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .first;

    Future<void> open(
      WidgetTester tester,
      FluentInfoButtonSize size, {
      FluentThemeData? theme,
    }) async {
      // A fresh State per call: re-pumping the same key keeps the old one, and
      // the second tap of a loop would toggle the tip shut rather than open.
      await tester.pumpWidget(const SizedBox.shrink());
      await pump(
        tester,
        FluentInfoButton(
          key: key,
          size: size,
          semanticLabel: 'More information',
          info: const Text('Kept for 30 days', key: tipKey),
        ),
        theme: theme,
      );
      await tester.tap(find.byKey(key));
      await tester.pump();
    }

    testWidgets('carries the popover surface tokens', (tester) async {
      await open(tester, FluentInfoButtonSize.medium);
      final decoration = tipDecoration(tester);
      expect(decoration.color, light.colors.neutralBackground1);
      expect(decoration.borderRadius, FluentRadius.allMedium);
      expect(decoration.border!.top.color, light.colors.transparentStroke);
      expect(decoration.border!.top.width, FluentStroke.thin);
      expect(decoration.boxShadow, light.shadow(FluentElevation.shadow16));
    });

    testWidgets('padding and type ramp follow the button size', (tester) async {
      // useInfoButtonStyles maps small and medium onto the popover's `small`
      // size (12 padding, caption1) and large onto `medium` (16, body1).
      const expected = <FluentInfoButtonSize, (double, double)>{
        FluentInfoButtonSize.small: (FluentSpacing.m, 12),
        FluentInfoButtonSize.medium: (FluentSpacing.m, 12),
        FluentInfoButtonSize.large: (FluentSpacing.l, 14),
      };
      for (final entry in expected.entries) {
        await open(tester, entry.key);
        expect(
          tester
              .widgetList<Padding>(
                find.ancestor(
                  of: find.byKey(tipKey),
                  matching: find.byType(Padding),
                ),
              )
              .first
              .padding
              .resolve(TextDirection.ltr),
          EdgeInsets.all(entry.value.$1),
          reason: '${entry.key.name}: padding',
        );
        expect(
          resolvedTextStyleOf(tester, of: find.byKey(tipKey)).fontSize,
          entry.value.$2,
          reason: '${entry.key.name}: type ramp',
        );
      }
    });

    testWidgets('wraps at 264', (tester) async {
      await open(tester, FluentInfoButtonSize.medium);
      final box = tester
          .widgetList<ConstrainedBox>(
            find.ancestor(
              of: find.byKey(tipKey),
              matching: find.byType(ConstrainedBox),
            ),
          )
          .firstWhere((b) => b.constraints.maxWidth.isFinite);
      expect(box.constraints.maxWidth, 264);
    });

    testWidgets('sits above the trigger with their start edges flush', (
      tester,
    ) async {
      await open(tester, FluentInfoButtonSize.medium);
      final trigger = tester.getRect(find.byKey(key));
      final tip = tester.getRect(
        find
            .ancestor(
              of: find.byKey(tipKey),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(tip.left, trigger.left, reason: 'above-START');
      expect(
        tip.bottom,
        trigger.top - FluentSpacing.xs,
        reason: 'above, held off by the offset',
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
        FluentInfoButtonTheme(
          style: FluentInfoButtonStyle.from(backgroundColor: themed),
          child: FluentInfoButton(
            key: key,
            semanticLabel: 'More information',
            style: FluentInfoButtonStyle.from(backgroundColor: explicit),
            info: const Text('Info'),
          ),
        ),
      );
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults, and reaches the tip', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentInfoButtonTheme(
          style: FluentInfoButtonStyle.from(
            backgroundColor: themed,
            infoBackgroundColor: themed,
          ),
          child: const FluentInfoButton(
            key: key,
            semanticLabel: 'More information',
            info: Text('Info', key: tipKey),
          ),
        ),
      );
      expect(decorationOf(tester).color, themed);

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(
        tester
            .widgetList<DecoratedBox>(
              find.ancestor(
                of: find.byKey(tipKey),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .first
            .color,
        themed,
        reason: 'the overlay must see the trigger\'s subtree theme',
      );
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInfoButton(
          key: key,
          semanticLabel: 'More information',
          style: FluentInfoButtonStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
          info: const Text('Info'),
        ),
      );
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        iconThemeOf(tester).color,
        light.colors.neutralForeground2,
        reason: 'overriding the radius must not drop the glyph token',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentInfoButtonBaseState(
        enabled: true,
        icon: Icon(FluentIcons.info_16_regular),
        activeIcon: Icon(FluentIcons.info_16_filled),
        info: Text('Info'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInfoButton(
            base,
            FluentInfoButtonStyle.from(
              backgroundColor: mine,
              foregroundColor: mine,
              borderRadius: FluentRadius.allLarge,
              padding: const EdgeInsets.all(6),
              iconSize: 8,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(decorationOf(tester).color, mine);
      expect(decorationOf(tester).borderRadius, FluentRadius.allLarge);
      expect(iconThemeOf(tester).size, 8);
      expect(tester.getSize(find.byKey(key)), const Size(20, 20));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentInfoButtonState(
        size: FluentInfoButtonSize.large,
        info: const Text('Info'),
      );
      final adjusted = resolveFluentInfoButtonStyle(state, light).merge(
        FluentInfoButtonStyle.from(borderRadius: FluentRadius.allCircular),
      );
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInfoButton(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(iconThemeOf(tester).size, FluentSize.size200);
      expect(tester.getSize(find.byKey(key)), const Size(24, 24));
    });

    testWidgets('an explicit icon suppresses the filled swap', (tester) async {
      const custom = Icon(FluentIcons.add_16_regular);
      final state = resolveFluentInfoButtonState(
        icon: custom,
        info: const Text('Info'),
      );
      expect(state.icon, same(custom));
      expect(
        state.activeIcon,
        same(custom),
        reason: 'upstream has one icon slot; overriding it overrides both',
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the glyph', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralForeground2: magenta},
            child: Center(
              child: FluentInfoButton(
                key: key,
                semanticLabel: 'More information',
                info: Text('Info'),
              ),
            ),
          ),
        ),
      );
      expect(iconThemeOf(tester).color, magenta);
    });

    testWidgets('high contrast paints nothing invisible', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentInfoButton(
          key: key,
          semanticLabel: 'More information',
          info: Text('Info', key: tipKey),
        ),
        theme: theme,
      );
      await tester.tap(find.byKey(key));
      await tester.pump();

      // The trigger carries no border at all in Figma, so the surface separator
      // that MUST survive high contrast is the tip's: transparentStroke becomes
      // canvasText there, and without it the surface has no edge.
      final tip = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byKey(tipKey),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .first;
      expect(tip.border, isNotNull);
      expect(tip.border!.top.color.a, 1.0);
      expect(tip.color!.a, 1.0);
      expect(iconThemeOf(tester).color!.a, 1.0);
    });
  });

  group('semantics', () {
    testWidgets('announces a labelled button that expands', (tester) async {
      await pump(
        tester,
        const FluentInfoButton(
          key: key,
          semanticLabel: 'About the retention period',
          info: Text('Kept for 30 days'),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'About the retention period',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'About the retention period',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
    });
  });
}
