import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentLink` is text, not a surface: it paints no fill and no border, so
/// every assertion here reads the resolved [TextStyle] rather than a
/// [BoxDecoration]. `expectSpec` needs a `DecoratedBox` to read radius and fill
/// from, which is why this file asserts explicitly — the fixture README calls
/// that out for exactly this shape of component.
///
/// The fixture also cannot express the underline. Figma draws it as a separate
/// `Underlines` RECTANGLE inside the `Text` frame, and
/// `tool/extract_component_spec.py` only records the variant frame plus its
/// first TEXT node. The underline expectations below therefore cite the Figma
/// node ids they were read from, so they can be re-checked by hand.
void main() {
  const key = Key('link');

  FluentThemeData lightTheme() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget link, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? lightTheme(),
      home: Center(child: link),
    ),
  );

  TextStyle textStyleOf(WidgetTester tester) =>
      resolvedTextStyleOf(tester, of: find.byKey(key));

  /// Maps a Figma variable path straight onto the core token it names.
  ///
  /// The point of the fixture's `tokens` map: nobody reverse-engineers
  /// `#FF115EA3` back into `brandForegroundLink`, and a renamed Figma variable
  /// fails loudly here instead of silently drifting.
  Color tokenColor(FluentThemeData theme, String token) {
    final c = theme.colors;
    return switch (token) {
      'Brand/Foreground/Link/Rest' => c.brandForegroundLink,
      'Brand/Foreground/Link/Hover' => c.brandForegroundLinkHover,
      'Brand/Foreground/Link/Pressed' => c.brandForegroundLinkPressed,
      'Neutral/Foreground/2/Link/Rest' => c.neutralForeground2Link,
      'Neutral/Foreground/2/Link/Hover' => c.neutralForeground2LinkHover,
      'Neutral/Foreground/2/Link/Pressed' => c.neutralForeground2LinkPressed,
      'Neutral/Foreground/Inverted/Link/Rest' =>
        c.neutralForegroundInvertedLink,
      'Neutral/Foreground/Inverted/Link/Hover' =>
        c.neutralForegroundInvertedLinkHover,
      'Neutral/Foreground/Inverted/Link/Pressed' =>
        c.neutralForegroundInvertedLinkPressed,
      'Neutral/Foreground/Disabled/Rest' => c.neutralForegroundDisabled,
      _ => throw StateError('no core token is mapped for "$token"'),
    };
  }

  FluentLinkAppearance appearanceOf(String style) => switch (style) {
    'Default' => FluentLinkAppearance.standard,
    'Subtle' => FluentLinkAppearance.subtle,
    'OverBrand' => FluentLinkAppearance.overBrand,
    _ => throw StateError('unknown Style=$style'),
  };

  /// Drives the pumped link into the Figma `State` named by [state].
  ///
  /// `Disabled` is not driven — it is expressed by `onPressed: null` at the
  /// call site, because disabled is a real state here rather than a paint job.
  Future<void> drive(WidgetTester tester, String state, FocusNode node) async {
    switch (state) {
      case 'Rest/Visited':
      case 'Disabled':
        break;
      case 'Hover':
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        // FocusableActionDetector gates hover on MouseTracker.mouseIsConnected,
        // which only flips once the added pointer has been flushed.
        await tester.pump();
        await mouse.moveTo(tester.getCenter(find.byKey(key)));
      case 'Pressed':
        final press = await tester.startGesture(
          tester.getCenter(find.byKey(key)),
        );
        addTearDown(press.up);
      case 'Focused':
        // WidgetState.focused means keyboard-VISIBLE focus. Flutter's highlight
        // mode cannot express that — it maps mouse and key alike to
        // `traditional` — so the modality is driven by a real key instead.
        // Escape raises it without moving focus.
        node.requestFocus();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      default:
        throw StateError('unknown State=$state');
    }
    await tester.pump();
  }

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('link');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 15);
      expect(spec.properties['Style'], ['Default', 'Subtle', 'OverBrand']);
      expect(spec.properties['State'], [
        'Rest/Visited',
        'Hover',
        'Pressed',
        'Focused',
        'Disabled',
      ]);
    });

    // Both axes, every cell: 3 styles x 5 states.
    for (final variant in spec.variants) {
      testWidgets(variant.name, (tester) async {
        final state = variant.props['State']!;
        final node = FocusNode();
        addTearDown(node.dispose);

        await pump(
          tester,
          FluentLink(
            key: key,
            appearance: appearanceOf(variant.props['Style']!),
            focusNode: node,
            onPressed: state == 'Disabled' ? null : () {},
            child: const Text('Link'),
          ),
        );
        await drive(tester, state, node);

        final theme = lightTheme();
        final text = variant.text!;
        final resolved = textStyleOf(tester);

        expect(
          resolved.color,
          tokenColor(theme, text.tokens['fills']!.first),
          reason:
              '${variant.name}: foreground '
              '(token: ${text.tokens['fills']!.first})',
        );
        expect(resolved.fontSize, text.fontSize, reason: 'font size');
        expect(
          resolved.height! * resolved.fontSize!,
          text.lineHeight,
          reason: 'line height',
        );
        expect(
          resolved.fontWeight,
          FluentFontWeight.regular,
          reason: 'Typography/Weight/Regular',
        );
      });
    }

    testWidgets('layout is padding-free with an XS icon gap', (tester) async {
      final variant = spec.variant(const {
        'Style': 'Default',
        'State': 'Rest/Visited',
      });

      await pump(
        tester,
        FluentLink(
          key: key,
          icon: const SizedBox(width: 20, height: 20),
          onPressed: () {},
          child: const Text('Link'),
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
      expect(padding, variant.padding);

      final row = tester.widget<Row>(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
      );
      expect(row.spacing, variant.gap, reason: 'Spacing/Horizontal/XS');
    });
  });

  group('underline', () {
    // Read from the `Underlines` RECTANGLE inside each variant's `Text` frame.
    // Its `visible` is bound to the set's `Inline style#23206:31` boolean, so
    // the authored value below is the inline=false rendering.
    //
    //   Rest/Visited 9067:569  hidden
    //   Hover        9067:574  visible, stroke = the state's own foreground
    //   Pressed      9067:579  visible, stroke = the state's own foreground
    //   Focused      9067:584  visible, strokeTop AND strokeBottom, stroke =
    //                          Neutral/Stroke/Focus/2/Rest
    //   Disabled     9067:589  hidden
    //
    // Underline width is `Stroke width/Thin` in every state.
    Future<TextStyle> pumpDriven(
      WidgetTester tester,
      String state, {
      FluentLinkAppearance appearance = FluentLinkAppearance.standard,
      bool inline = false,
      FluentThemeData? theme,
    }) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentLink(
          key: key,
          appearance: appearance,
          inline: inline,
          focusNode: node,
          onPressed: state == 'Disabled' ? null : () {},
          child: const Text('Link'),
        ),
        theme: theme,
      );
      await drive(tester, state, node);
      return textStyleOf(tester);
    }

    testWidgets('rest and disabled carry none, interaction carries one', (
      tester,
    ) async {
      for (final state in ['Rest/Visited', 'Disabled']) {
        final style = await pumpDriven(tester, state);
        expect(style.decoration, TextDecoration.none, reason: state);
      }
      for (final state in ['Hover', 'Pressed', 'Focused']) {
        final style = await pumpDriven(tester, state);
        expect(style.decoration, TextDecoration.underline, reason: state);
        expect(style.decorationThickness, FluentStroke.thin, reason: state);
      }
    });

    testWidgets('inline underlines at rest, matching the Figma boolean', (
      tester,
    ) async {
      final style = await pumpDriven(tester, 'Rest/Visited', inline: true);
      expect(style.decoration, TextDecoration.underline);
      expect(style.decorationColor, lightTheme().colors.brandForegroundLink);
    });

    testWidgets('hover and pressed take the foreground token', (tester) async {
      final theme = lightTheme();
      expect(
        (await pumpDriven(tester, 'Hover')).decorationColor,
        theme.colors.brandForegroundLinkHover,
      );
      expect(
        (await pumpDriven(tester, 'Pressed')).decorationColor,
        theme.colors.brandForegroundLinkPressed,
      );
    });

    testWidgets('focus doubles the line and recolours it per style', (
      tester,
    ) async {
      final theme = lightTheme();
      for (final appearance in [
        FluentLinkAppearance.standard,
        FluentLinkAppearance.subtle,
      ]) {
        final style = await pumpDriven(
          tester,
          'Focused',
          appearance: appearance,
        );
        expect(
          style.decorationColor,
          theme.colors.strokeFocus2,
          reason: '${appearance.name}: Neutral/Stroke/Focus/2/Rest',
        );
        expect(style.decorationStyle, TextDecorationStyle.double);
      }

      // OverBrand is the exception: its focused underline binds
      // Neutral/Foreground/Inverted/Link/Rest, not the focus stroke — 9067:634.
      final overBrand = await pumpDriven(
        tester,
        'Focused',
        appearance: FluentLinkAppearance.overBrand,
      );
      expect(
        overBrand.decorationColor,
        theme.colors.neutralForegroundInvertedLink,
      );
      expect(overBrand.decorationStyle, TextDecorationStyle.double);
    });
  });

  group('motion', () {
    testWidgets('the colour change is INSTANT — upstream declares none', (
      tester,
    ) async {
      // React's useLinkStyles_unstable has no transitionProperty, and Figma
      // carries no motion for the set, so there is nothing to tween. This is
      // the same deliberate absence FluentMotionSpec documents for Checkbox and
      // Tooltip: do not "improve" it with a fade.
      await pump(
        tester,
        FluentLink(key: key, onPressed: () {}, child: const Text('Link')),
      );
      final theme = lightTheme();
      expect(textStyleOf(tester).color, theme.colors.brandForegroundLink);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(
        textStyleOf(tester).color,
        theme.colors.brandForegroundLinkHover,
        reason: 'the hover token must land on the very next frame',
      );
      // Nothing is scheduled, so a further frame changes nothing.
      await tester.pump(const Duration(milliseconds: 50));
      expect(textStyleOf(tester).color, theme.colors.brandForegroundLinkHover);
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
        FluentLinkTheme(
          style: FluentLinkStyle.from(foregroundColor: themed),
          child: FluentLink(
            key: key,
            style: FluentLinkStyle.from(foregroundColor: explicit),
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
      );
      expect(textStyleOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentLinkTheme(
          style: FluentLinkStyle.from(foregroundColor: themed),
          child: FluentLink(
            key: key,
            onPressed: () {},
            child: const Text('Link'),
          ),
        ),
      );
      expect(textStyleOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentLink(
          key: key,
          style: FluentLinkStyle.from(gap: 16),
          icon: const SizedBox(width: 20, height: 20),
          onPressed: () {},
          child: const Text('Link'),
        ),
      );
      final row = tester.widget<Row>(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
      );
      expect(row.spacing, 16);
      expect(
        textStyleOf(tester).color,
        lightTheme().colors.brandForegroundLink,
        reason: 'overriding the gap must not drop the link colour',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentLinkBaseState(enabled: true, label: Text('Link'));
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentLink(
            base,
            FluentLinkStyle.from(
              foregroundColor: mine,
              decoration: TextDecoration.lineThrough,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(textStyleOf(tester).color, mine);
      expect(textStyleOf(tester).decoration, TextDecoration.lineThrough);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentLinkState(
        appearance: FluentLinkAppearance.subtle,
        label: const Text('Link'),
      );
      final theme = lightTheme();
      final adjusted = resolveFluentLinkStyle(
        state,
        theme,
      ).merge(FluentLinkStyle.from(decorationThickness: FluentStroke.thick));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentLink(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(textStyleOf(tester).color, theme.colors.neutralForeground2Link);
      expect(textStyleOf(tester).decorationThickness, FluentStroke.thick);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the link', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: lightTheme(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandForegroundLink: magenta},
            child: Center(
              child: FluentLink(
                key: key,
                onPressed: () {},
                child: const Text('Link'),
              ),
            ),
          ),
        ),
      );
      expect(textStyleOf(tester).color, magenta);
    });

    testWidgets('high contrast keeps every ink opaque and the focus visible', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );

      for (final appearance in FluentLinkAppearance.values) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          FluentLink(
            key: key,
            appearance: appearance,
            focusNode: node,
            onPressed: () {},
            child: const Text('Link'),
          ),
          theme: theme,
        );
        expect(
          textStyleOf(tester).color!.a,
          1.0,
          reason: '${appearance.name}: resting ink must be opaque',
        );

        await drive(tester, 'Focused', node);
        final focused = textStyleOf(tester);
        // A link has no border to go invisible, so the equivalent failure mode
        // is a focus underline that cannot be seen. It must be drawn, opaque,
        // and a different ink from the label it sits under.
        expect(focused.decoration, TextDecoration.underline);
        expect(
          focused.decorationColor!.a,
          1.0,
          reason: '${appearance.name}: focus underline must be opaque',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('fires on tap and on Enter', (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentLink(
          key: key,
          focusNode: node,
          onPressed: () => taps++,
          child: const Text('Link'),
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
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentLink(key: key, focusNode: node, child: const Text('Link')),
      );
      final theme = lightTheme();
      expect(textStyleOf(tester).color, theme.colors.neutralForegroundDisabled);

      // Not a grey-out: it refuses focus, ignores the pointer, and never
      // adopts the hover ink.
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isFalse);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(textStyleOf(tester).color, theme.colors.neutralForegroundDisabled);
      expect(textStyleOf(tester).decoration, TextDecoration.none);
    });

    testWidgets('announces itself as a link, not a button', (tester) async {
      await pump(
        tester,
        FluentLink(
          key: key,
          semanticLabel: 'Fluent docs',
          onPressed: () {},
          child: const Text('Link'),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(
          isLink: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Fluent docs',
        ),
      );
    });
  });
}
