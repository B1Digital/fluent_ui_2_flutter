import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentCard` is the first *container* in the package, so these tests cover
/// two things the button never had to: a card is interactive only when given an
/// `onPressed`, and `disabled` is an axis of its own rather than the absence of
/// a callback. Both are asserted as behaviour, not as a paint job.
void main() {
  const key = Key('card');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget card, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      home: Center(child: card),
    ),
  );

  Iterable<BoxDecoration> decorationsOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>();

  /// The filled surface — the only decoration carrying a colour.
  BoxDecoration surfaceOf(WidgetTester tester) =>
      decorationsOf(tester).firstWhere((d) => d.color != null);

  /// The foreground border decoration, or null when the card draws no border.
  Border? borderOf(WidgetTester tester) {
    final borders = decorationsOf(
      tester,
    ).map((d) => d.border).whereType<Border>().toList();
    return borders.isEmpty ? null : borders.first;
  }

  /// The inset applied to every slot except the preview.
  EdgeInsets paddingOf(WidgetTester tester) => tester
      .widgetList<Padding>(
        find.descendant(of: find.byKey(key), matching: find.byType(Padding)),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
    return mouse;
  }

  /// Every number and every token below comes from `test/fixtures/card.json`,
  /// extracted from component set `9230:4927` on the Card page. The style
  /// resolver is exercised directly rather than through a pumped widget: Figma's
  /// Hover and Pressed variants are separate frames, and resolving the
  /// [WidgetStateProperty] against an explicit state set compares exactly what
  /// Figma states, with no gesture plumbing in between.
  group('pixel fidelity against Figma', () {
    final spec = loadSpec('card');

    const appearances = <String, FluentCardAppearance>{
      'Filled': FluentCardAppearance.filled,
      'Filled alt': FluentCardAppearance.filledAlternative,
      'Outline': FluentCardAppearance.outline,
      'Subtle': FluentCardAppearance.subtle,
    };

    /// Figma's `Draggable` is a drag affordance with no counterpart here — every
    /// appearance renders as a lifted Filled card while dragging — so it is
    /// deliberately absent rather than silently mismatched.
    const interactionStates = <String, Set<WidgetState>>{
      'Rest': <WidgetState>{},
      'Hover': <WidgetState>{WidgetState.hovered},
      'Pressed': <WidgetState>{WidgetState.pressed},
      'Selected': <WidgetState>{WidgetState.selected},
      'Disabled': <WidgetState>{WidgetState.disabled},
    };

    /// Figma cannot store a colour without an RGB triple, so it records a fully
    /// transparent token as transparent *white* while core stores CSS
    /// `transparent`, which is transparent *black*. Both are invisible, so a
    /// zero-alpha value is compared on alpha alone — see
    /// `doc/token-divergences.md`.
    void expectColor(Color actual, Color expected, String reason) {
      if (expected.a == 0) {
        expect(actual.a, 0, reason: '$reason — expected fully transparent');
        return;
      }
      expect(actual.toARGB32(), expected.toARGB32(), reason: reason);
    }

    FluentCardStyle styleFor(FluentCardAppearance appearance, String state) =>
        resolveFluentCardStyle(
          resolveFluentCardState(
            enabled: state != 'Disabled',
            interactive: true,
            selected: state == 'Selected',
            appearance: appearance,
          ),
          light,
        );

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 28);
      expect(
        spec.properties.keys,
        containsAll(<String>['Layout', 'State', 'Style']),
      );
    });

    test('every Style x State surface, border and geometry matches', () {
      for (final appearance in appearances.entries) {
        for (final state in interactionStates.entries) {
          final variant = spec.variant(<String, String>{
            'Layout': 'Default',
            'Style': appearance.key,
            'State': state.key,
          });
          final style = styleFor(appearance.value, state.key);
          final states = state.value;

          expectColor(
            style.backgroundColor!.resolve(states)!,
            variant.fill!,
            '${variant.name}: fill (${variant.token('fills')})',
          );
          expectColor(
            style.borderColor!.resolve(states)!,
            variant.stroke!,
            '${variant.name}: border (${variant.token('strokes')})',
          );
          expect(
            style.borderWidth!.resolve(states),
            variant.strokeWidth,
            reason:
                '${variant.name}: border width '
                '(${variant.token('strokeWidth')})',
          );
          expect(
            style.borderRadius!.resolve(states),
            variant.radius,
            reason: '${variant.name}: radius (${variant.token('radius')})',
          );
        }
      }
    });

    test('elevation matches the effect styles Figma binds', () {
      for (final appearance in appearances.entries) {
        for (final state in interactionStates.entries) {
          final variant = spec.variant(<String, String>{
            'Layout': 'Default',
            'Style': appearance.key,
            'State': state.key,
          });
          final elevated =
              appearance.value == FluentCardAppearance.filled ||
              appearance.value == FluentCardAppearance.filledAlternative;

          expect(
            styleFor(appearance.value, state.key).shadow!.resolve(state.value),
            !elevated
                ? isNull
                : state.key == 'Hover'
                ? light.shadow(FluentElevation.shadow8)
                : light.shadow(FluentElevation.shadow4),
            reason: '${variant.name}: shadow',
          );

          // Figma binds `Shadow/Key` + `Shadow/Ambient` on exactly the variants
          // we elevate, with one exception: Subtle/Rest binds them while Subtle
          // Hover, Pressed, Selected, Disabled and the Custom-layout Rest twin
          // bind nothing at all. One shadow across six Subtle variants is an
          // authoring slip, not a spec — recorded in doc/token-divergences.md.
          expect(
            variant.tokens.containsKey('effects'),
            elevated || (appearance.key == 'Subtle' && state.key == 'Rest'),
            reason: '${variant.name}: Figma effect binding',
          );
        }
      }
    });

    test('Medium padding comes from the Card padding collection', () {
      // Only the Custom layout carries the inset on the variant frame; the
      // Default layout spreads the same numbers across its slot containers.
      final variant = spec.variant(const <String, String>{
        'Layout': 'Custom',
        'State': 'Rest',
        'Style': 'Filled',
      });
      final style = resolveFluentCardStyle(resolveFluentCardState(), light);
      expect(
        style.padding!.resolve(const <WidgetState>{}),
        variant.padding,
        reason: 'padding (${variant.token('paddingLeft')})',
      );
      expect(variant.padding, const EdgeInsets.all(FluentSpacing.m));
    });
  });

  group('variant axes', () {
    testWidgets('geometry matches every size', (tester) async {
      const expected = <FluentCardSize, (double, BorderRadius)>{
        FluentCardSize.small: (FluentSpacing.s, FluentRadius.allSmall),
        FluentCardSize.medium: (FluentSpacing.m, FluentRadius.allMedium),
        FluentCardSize.large: (FluentSpacing.l, FluentRadius.allLarge),
      };

      for (final entry in expected.entries) {
        final (inset, radius) = entry.value;
        await pump(
          tester,
          FluentCard(
            key: key,
            size: entry.key,
            header: const Text('H'),
            child: const Text('B'),
          ),
        );

        expect(
          paddingOf(tester),
          EdgeInsets.all(inset),
          reason: '${entry.key.name}: padding',
        );
        expect(
          surfaceOf(tester).borderRadius,
          radius,
          reason: '${entry.key.name}: radius',
        );
        // Upstream drives padding and gap from one CSS variable, so they agree.
        // The inner column is the one holding the slots; the outer one holds
        // the preview and the padded group and never spaces them itself.
        expect(
          tester
              .widgetList<Column>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(Column),
                ),
              )
              .last
              .spacing,
          inset,
          reason: '${entry.key.name}: gap',
        );
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      final fills = <FluentCardAppearance, (Color, Color)>{
        FluentCardAppearance.filled: (
          light.colors.neutralBackground1,
          light.colors.transparentStrokeInteractive,
        ),
        FluentCardAppearance.filledAlternative: (
          light.colors.neutralBackground2,
          light.colors.transparentStrokeInteractive,
        ),
        FluentCardAppearance.outline: (
          light.colors.transparentBackground,
          light.colors.neutralStroke1,
        ),
        FluentCardAppearance.subtle: (
          light.colors.subtleBackground,
          light.colors.transparentStrokeInteractive,
        ),
      };

      for (final entry in fills.entries) {
        final (fill, stroke) = entry.value;
        await pump(
          tester,
          FluentCard(key: key, appearance: entry.key, child: const Text('B')),
        );
        expect(
          surfaceOf(tester).color,
          fill,
          reason: '${entry.key.name}: resting fill',
        );
        expect(
          borderOf(tester)!.top.color,
          stroke,
          reason: '${entry.key.name}: resting border',
        );
        expect(
          borderOf(tester)!.top.width,
          FluentStroke.thin,
          reason: '${entry.key.name}: border width',
        );
      }
    });

    testWidgets('only the filled appearances are elevated', (tester) async {
      const elevated = <FluentCardAppearance>{
        FluentCardAppearance.filled,
        FluentCardAppearance.filledAlternative,
      };
      for (final appearance in FluentCardAppearance.values) {
        await pump(
          tester,
          FluentCard(key: key, appearance: appearance, child: const Text('B')),
        );
        expect(
          surfaceOf(tester).boxShadow,
          elevated.contains(appearance)
              ? light.shadow(FluentElevation.shadow4)
              : isNull,
          reason: '${appearance.name}: resting shadow',
        );
      }
    });

    testWidgets('hover raises the fill and the elevation of a filled card', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCard(key: key, onPressed: () {}, child: const Text('B')),
      );
      await hover(tester);

      expect(surfaceOf(tester).color, light.colors.neutralBackground1Hover);
      expect(
        surfaceOf(tester).boxShadow,
        light.shadow(FluentElevation.shadow8),
      );
    });

    testWidgets('orientation picks the layout axis', (tester) async {
      await pump(
        tester,
        const FluentCard(
          key: key,
          orientation: FluentCardOrientation.horizontal,
          header: Text('H'),
          child: Text('B'),
        ),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
        findsWidgets,
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Column)),
        findsNothing,
      );
    });

    testWidgets('selected keeps the Selected tokens even while hovered', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCard(
          key: key,
          selected: true,
          onPressed: () {},
          child: const Text('B'),
        ),
      );
      expect(surfaceOf(tester).color, light.colors.neutralBackground1Selected);
      expect(borderOf(tester)!.top.color, light.colors.neutralStroke1Selected);

      await hover(tester);
      // Upstream's `filledInteractiveSelected` re-declares the Selected fill
      // inside `:hover`, so selection outranks hover rather than the reverse.
      expect(surfaceOf(tester).color, light.colors.neutralBackground1Selected);
    });
  });

  group('motion', () {
    testWidgets('the hover fill applies instantly — upstream has no transition', (
      tester,
    ) async {
      // `useCardStyles.styles.ts` on master declares no `transition` at all, on
      // the root or any slot. A card that tweened would be inventing motion.
      await pump(
        tester,
        FluentCard(key: key, onPressed: () {}, child: const Text('B')),
      );
      await tester.pumpAndSettle();

      await hover(tester);
      expect(
        surfaceOf(tester).color,
        light.colors.neutralBackground1Hover,
        reason: 'the very first frame after hover must already be the target',
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
        FluentCardTheme(
          style: FluentCardStyle.from(backgroundColor: themed),
          child: FluentCard(
            key: key,
            style: FluentCardStyle.from(backgroundColor: explicit),
            child: const Text('B'),
          ),
        ),
      );
      expect(surfaceOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentCardTheme(
          style: FluentCardStyle.from(backgroundColor: themed),
          child: const FluentCard(key: key, child: Text('B')),
        ),
      );
      expect(surfaceOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCard(
          key: key,
          style: FluentCardStyle.from(borderRadius: FluentRadius.allCircular),
          child: const Text('B'),
        ),
      );
      expect(surfaceOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        surfaceOf(tester).color,
        light.colors.neutralBackground1,
        reason: 'overriding radius must not drop the resolved fill',
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the card', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralBackground1: magenta},
            child: Center(
              child: FluentCard(key: key, child: Text('B')),
            ),
          ),
        ),
      );
      expect(surfaceOf(tester).color, magenta);
    });

    testWidgets('high contrast draws no invisible border', (tester) async {
      for (final appearance in FluentCardAppearance.values) {
        await pump(
          tester,
          FluentCard(key: key, appearance: appearance, child: const Text('B')),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        );
        // transparentStroke becomes canvasText in high contrast, so the border
        // that is invisible in light is the card's only outline here.
        expect(
          borderOf(tester)!.top.color.a,
          1.0,
          reason: '${appearance.name}: border must be opaque in high contrast',
        );
      }
    });
  });

  group('interactive versus inert', () {
    testWidgets('a card with no onPressed is inert, not disabled', (
      tester,
    ) async {
      await pump(tester, const FluentCard(key: key, child: Text('B')));
      expect(
        surfaceOf(tester).color,
        light.colors.neutralBackground1,
        reason: 'an inert card keeps its resting fill',
      );

      await hover(tester);
      expect(
        surfaceOf(tester).color,
        light.colors.neutralBackground1,
        reason: 'an inert card must not respond to hover either',
      );
    });

    testWidgets('onPressed fires on tap and on Enter', (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentCard(
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

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentCard(
          key: key,
          focusNode: node,
          disabled: true,
          onPressed: () => taps++,
          child: const Text('B'),
        ),
      );

      expect(surfaceOf(tester).color, light.colors.neutralBackgroundDisabled);
      // A disabled Filled card shows no border. Figma binds
      // `Neutral/Stroke/Transparent/Disabled/Rest`; only Outline reaches for the
      // visible `neutralStrokeDisabled`.
      expect(
        borderOf(tester)!.top.color,
        light.colors.transparentStrokeDisabled,
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0, reason: 'a disabled card must not invoke its callback');

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isFalse, reason: 'a disabled card refuses focus');

      await hover(tester);
      expect(
        surfaceOf(tester).color,
        light.colors.neutralBackgroundDisabled,
        reason: 'a disabled card must not adopt the hover fill',
      );
    });

    testWidgets('an inert card can still be disabled', (tester) async {
      await pump(
        tester,
        const FluentCard(key: key, disabled: true, child: Text('B')),
      );
      expect(surfaceOf(tester).color, light.colors.neutralBackgroundDisabled);
    });
  });

  group('semantics', () {
    testWidgets('an interactive card announces itself as a button', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCard(
          key: key,
          semanticLabel: 'Weekly report',
          onPressed: () {},
          // No text in the slots: a Semantics annotation merges its subtree's
          // labels, and this assertion is about the flags, not the copy.
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Weekly report',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a selected card announces its selection', (tester) async {
      await pump(
        tester,
        FluentCard(
          key: key,
          semanticLabel: 'Weekly report',
          selected: true,
          onPressed: () {},
          child: const SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Weekly report',
          isButton: true,
          isEnabled: true,
          isSelected: true,
          isFocusable: true,
          hasEnabledState: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('an inert card is not announced as a button', (tester) async {
      await pump(
        tester,
        const FluentCard(
          key: key,
          semanticLabel: 'Weekly report',
          child: SizedBox(width: 40, height: 40),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Weekly report'),
      );
    });
  });

  group('layout', () {
    testWidgets('the preview bleeds to the card edge, the slots do not', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: FluentCard(
            key: key,
            preview: SizedBox(height: 100, child: Text('P')),
            child: Text('B'),
          ),
        ),
      );

      final card = tester.getRect(find.byKey(key));
      final preview = tester.getRect(find.text('P'));
      final body = tester.getRect(find.text('B'));

      expect(preview.top, card.top, reason: 'preview is flush with the top');
      expect(body.left, card.left + FluentSpacing.m, reason: 'body is inset');
      expect(
        body.top,
        preview.bottom + FluentSpacing.m,
        reason: 'one gap between the preview and the first padded slot',
      );
    });

    testWidgets('the focus ring is drawn INSIDE the card, flush with its edge', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentCard(
          key: key,
          focusNode: node,
          onPressed: () {},
          child: const Text('B'),
        ),
      );

      final resting = borderOf(tester);
      expect(
        resting?.top.width,
        FluentStroke.thin,
        reason: 'the resting card carries its 1px appearance border',
      );
      final size = tester.getSize(find.byKey(key));

      // Tab rather than `node.requestFocus()`: the ring follows *keyboard*
      // focus, which needs the focus highlight mode a key event sets.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(node.hasFocus, isTrue);

      // The card is the one component React pulls its ring inward on:
      // `useCardStyles.styles.ts` sets `outlineOffset: '-2px'` on top of
      // `createFocusOutlineStyle`'s own -2px, so the 2px band lands at -2…0 —
      // a 396x356 `::after` inside a 400x360 card. Figma agrees on the box: its
      // `Focus ring` frame is the component's own size, not an inflated one.
      final focused = borderOf(tester);
      expect(focused?.top.color, light.colors.strokeFocus2);
      expect(focused?.top.width, FluentStroke.thick);
      expect(
        focused?.top.strokeAlign,
        BorderSide.strokeAlignInside,
        reason: 'the band belongs at -2…0, never outside the card',
      );
      expect(
        tester.getSize(find.byKey(key)),
        size,
        reason: 'a foreground border consumes no layout',
      );
    });

    testWidgets('the clip stays below the border, never above it', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: FluentCard(
            key: key,
            preview: SizedBox(height: 100, child: Text('P')),
            child: Text('B'),
          ),
        ),
      );

      // The preview bleeds to the card edge, so the clip that rounds its
      // corners has to sit under the foreground border — and under the focus
      // ring, which reuses that same border slot.
      final border = find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox && w.position == DecorationPosition.foreground,
        ),
      );
      expect(
        find.descendant(of: border, matching: find.byType(ClipRRect)),
        findsOneWidget,
        reason: 'the clip must be INSIDE the bordered box',
      );
      expect(
        find.ancestor(of: border, matching: find.byType(ClipRRect)),
        findsNothing,
        reason: 'nothing above may clip it',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentCardBaseState(
        enabled: true,
        interactive: false,
        selected: false,
        orientation: FluentCardOrientation.vertical,
        body: Text('B'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentCard(
            base,
            FluentCardStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
              padding: const EdgeInsets.all(FluentSpacing.l),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(surfaceOf(tester).color, mine);
      expect(surfaceOf(tester).borderRadius, FluentRadius.allLarge);
      expect(paddingOf(tester), const EdgeInsets.all(FluentSpacing.l));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentCardState(
        appearance: FluentCardAppearance.outline,
        body: const Text('B'),
      );
      final adjusted = resolveFluentCardStyle(
        state,
        light,
      ).merge(FluentCardStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentCard(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(surfaceOf(tester).color, light.colors.transparentBackground);
      expect(surfaceOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });
}
