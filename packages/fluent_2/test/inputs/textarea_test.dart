import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTextarea` is the package's first text input, so these tests cover the
/// editing contract as well as the look of upstream's Textarea as it renders in
/// Chrome: focus, keyboard, selection, the bottom border and the focus bar.
void main() {
  const key = Key('textarea');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget textarea, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Center(child: SizedBox(width: 280, child: textarea)),
    ),
  );

  /// The field's own decorated surface — the first `DecoratedBox` in the
  /// subtree, which is the one carrying the fill and the corner radius.
  BoxDecoration surfaceOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// The field's border, read as the tones the painter was handed.
  FluentInputBorderPainter borderOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byKey(fluentTextareaUnderlineKey),
                ),
              )
              .painter!
          as FluentInputBorderPainter;

  /// How far the brand focus rule has scaled in, 0 to 1.
  ///
  /// The scale lives inside [FluentInputFocusUnderline], which is what the key
  /// now identifies.
  double focusRuleScaleOf(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byKey(fluentTextareaFocusUnderlineKey),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .storage[0];

  BoxDecoration focusRuleOf(WidgetTester tester) =>
      tester
              .widget<DecoratedBox>(
                find.descendant(
                  of: find.byKey(fluentTextareaFocusUnderlineKey),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .decoration
          as BoxDecoration;

  const styleNames = <FluentTextareaAppearance, String>{
    FluentTextareaAppearance.outline: 'Outline',
    FluentTextareaAppearance.filledDarker: 'Filled darker',
    FluentTextareaAppearance.filledLighter: 'Filled lighter',
  };
  const sizeNames = <FluentTextareaSize, String>{
    FluentTextareaSize.small: 'Small',
    FluentTextareaSize.medium: 'Medium',
    FluentTextareaSize.large: 'Large',
  };

  // The oracle is upstream's `useTextareaStyles.styles.ts` as it renders in
  // Chrome on the live storybook. The Figma fixture supplies the numbers where
  // the two agree; where they do not, the upstream value is asserted directly
  // and the Figma one is noted beside it.
  group('pixel fidelity against upstream', () {
    final spec = loadSpec('textarea');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 63);
      expect(spec.properties['Style'], styleNames.values.toList());
      expect(spec.properties['State'], <String>[
        'Rest',
        'Hover',
        'Pressed',
        'Focus',
        'Error',
        'Disabled',
        'Read only',
      ]);
    });

    testWidgets('height, text inset and type ramp match every size', (
      tester,
    ) async {
      // Upstream's border box is 44 / 56 / 68: the `<textarea>`'s `min-height`
      // 40 / 52 / 64, the root's 2px `padding-bottom` and the 1px border. The
      // text starts at the 1px border plus the `<textarea>`'s padding. Figma
      // draws Medium 52 tall with a flat 6 of vertical inset at every size.
      const geometry = <FluentTextareaSize, (double, Offset)>{
        FluentTextareaSize.small: (44, Offset(9, 5)),
        FluentTextareaSize.medium: (56, Offset(13, 7)),
        FluentTextareaSize.large: (68, Offset(15, 9)),
      };
      for (final size in FluentTextareaSize.values) {
        final variant = spec.variant({
          'Style': 'Outline',
          'Size': sizeNames[size]!,
          'State': 'Rest',
        });
        final (height, text) = geometry[size]!;

        await pump(tester, FluentTextarea(key: key, size: size));
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(key)).height,
          height,
          reason: '${size.name}: height',
        );
        expect(
          tester.getTopLeft(find.byType(EditableText)) -
              tester.getTopLeft(find.byKey(key)),
          text,
          reason: '${size.name}: text inset',
        );

        final type = variant.text!;
        final resolved = resolveFluentTextareaStyle(
          resolveFluentTextareaState(size: size),
          light(),
        ).textStyle!.resolve(const <WidgetState>{})!;
        expect(resolved.fontSize, type.fontSize, reason: '${size.name}: size');
        expect(
          resolved.height! * resolved.fontSize!,
          type.lineHeight,
          reason: '${size.name}: line height',
        );
        expect(
          surfaceOf(tester).borderRadius,
          variant.radius,
          reason: '${size.name}: radius',
        );
      }
    });

    testWidgets('the field holds two rows and scrolls, as upstream does', (
      tester,
    ) async {
      // `<textarea rows="2">` never grows: six lines typed into the storybook
      // field leave its root 56px tall and scroll the `<textarea>` instead.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, FluentTextarea(key: key, controller: controller));
      await tester.pumpAndSettle();
      controller.text = 'one\ntwo\nthree\nfour\nfive\nsix';
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)).height, 56);

      // And a mouse wheel over it scrolls the text, as it does in Chrome.
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byKey(key), matching: find.byType(Scrollable)),
      );
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        wheel.hover(tester.getCenter(find.byKey(key))),
      );
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 30)));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));

      // An explicit maxLines is the opt-in to growth.
      await pump(
        tester,
        FluentTextarea(key: key, controller: controller, maxLines: 4),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(key)).height,
        1 + 6 + 4 * 20 + 6 + 2 + 1,
      );
    });

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      // A CSS `height` sizes the border box, and `::after` sits on its bottom.
      await pump(
        tester,
        const SizedBox(height: 120, child: FluentTextarea(key: key)),
      );
      final painted = find.descendant(
        of: find.byKey(key),
        matching: find.byKey(fluentTextareaUnderlineKey),
      );
      final bar = find.byKey(fluentTextareaFocusUnderlineKey);
      expect(tester.getRect(painted).height, 120);
      expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      for (final entry in styleNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Rest',
        });
        final contents = variant.part('Contents');

        await pump(tester, FluentTextarea(key: key, appearance: entry.key));
        await tester.pumpAndSettle();

        expect(
          surfaceOf(tester).color,
          contents.fill,
          reason: '${entry.value}: resting fill',
        );

        final stroke = contents.stroke;
        if (stroke == null) {
          // Figma paints no stroke on the filled appearances; upstream paints
          // the transparent token, which high contrast makes opaque.
          expect(
            borderOf(tester).borderColor!.a,
            0,
            reason: '${entry.value}: border must be invisible in light',
          );
        } else {
          expect(
            borderOf(tester).borderColor,
            stroke,
            reason: '${entry.value}: resting border',
          );
        }

        // Only Outline gives its bottom side a colour of its own; the filled
        // appearances' transparent border runs round all four.
        final bottom = variant.parts.any((p) => p.name == 'Thin underline')
            ? variant.part('Thin underline').fill
            : null;
        expect(
          borderOf(tester).bottomBorderColor,
          bottom,
          reason: '${entry.value}: bottom side',
        );
        expect(borderOf(tester).bottomBorderWidth, FluentStroke.thin);
      }
    });

    testWidgets('hover and press walk the outline ramp; the bottom stays 1px', (
      tester,
    ) async {
      final c = light().colors;
      await pump(tester, const FluentTextarea(key: key));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(borderOf(tester).borderColor, c.neutralStroke1Hover);
      expect(
        borderOf(tester).bottomBorderColor,
        c.neutralStrokeAccessibleHover,
      );

      // Figma's Pressed variants swap to a 2px "Thick underline"; upstream's
      // `:active` recolours the 1px bottom border and never thickens it.
      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(
        borderOf(tester).bottomBorderColor,
        c.neutralStrokeAccessiblePressed,
      );
      expect(borderOf(tester).bottomBorderWidth, FluentStroke.thin);
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('focus moves the outline border, and hover wins over it', (
      tester,
    ) async {
      // Unlike Input, `outlineInteractive` writes `:focus-within` as its own
      // rule, which Griffel sorts before `:hover` and `:active`. Measured:
      // focused #b3b3b3 / #0f6cbd, focused and hovered #c7c7c7 / #575757,
      // focused and pressed #b3b3b3 / #4d4d4d.
      final c = light().colors;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, FluentTextarea(key: key, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(borderOf(tester).bottomBorderColor, c.compoundBrandStroke);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(borderOf(tester).borderColor, c.neutralStroke1Hover);
      expect(
        borderOf(tester).bottomBorderColor,
        c.neutralStrokeAccessibleHover,
      );

      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(
        borderOf(tester).bottomBorderColor,
        c.neutralStrokeAccessiblePressed,
      );
      expect(focusRuleOf(tester).color, c.compoundBrandStrokePressed);
      await mouse.up();
      await tester.pumpAndSettle();

      // Unlike the Combobox family, a `<textarea>` takes `:active` from a
      // right press too, focused or not (Chrome, every spot measured).
      final right = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(
        borderOf(tester).bottomBorderColor,
        c.neutralStrokeAccessiblePressed,
      );
      expect(focusRuleOf(tester).color, c.compoundBrandStrokePressed);
      await right.up();
      await tester.pumpAndSettle();
    });

    test('a focused filled field takes the Interactive stroke', () {
      // `filled` writes `:hover,:focus-within` as one rule. Both tokens are
      // transparent in light, so only high contrast shows the difference.
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in <FluentTextareaAppearance>[
        FluentTextareaAppearance.filledDarker,
        FluentTextareaAppearance.filledLighter,
      ]) {
        Color border({required bool focused}) => resolveFluentTextareaStyle(
          resolveFluentTextareaState(appearance: appearance, focused: focused),
          theme,
        ).borderColor!.resolve(const <WidgetState>{})!;
        expect(border(focused: false), theme.colors.transparentStroke);
        expect(
          border(focused: true),
          theme.colors.transparentStrokeInteractive,
          reason: appearance.name,
        );
      }
    });

    testWidgets('the bottom colour meets the sides on the CSS corner diagonal', (
      tester,
    ) async {
      // A browser splits two border colours along the line from the border
      // box's corner to the padding box's: here (0, h) → (1, h − 1), 45°. The
      // darker bottom colour therefore climbs half-way round each bottom arc
      // (outer radius 4, inner 3). At DPR 4, device pixel (7, 4h − 6) covers
      // CSS x 1.75–2, 1.25–1.5 above the bottom: wholly inside the ring, below
      // the diagonal, and above the bottom 1px — where the old 1px strip over
      // a uniform `#d1d1d1` border left the side colour. (4, 4h − 8), at CSS x
      // 1–1.25, 1.75–2 up, is the same arc above the diagonal.
      const boundary = Key('boundary');
      await pump(
        tester,
        const RepaintBoundary(
          key: boundary,
          child: FluentTextarea(key: key),
        ),
      );
      await tester.pumpAndSettle();
      const ratio = 4.0;
      final size = tester.getSize(find.byKey(boundary));
      final width = (size.width * ratio).round();
      final bottom = (size.height * ratio).round();

      final pixels = (await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
            .toImage(pixelRatio: ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;
      void expectPixel(int x, int y, Color expected, String reason) {
        final i = (y * width + x) * 4;
        final actual = [for (var c = 0; c < 3; c++) pixels.getUint8(i + c)];
        final want = [
          for (final channel in [expected.r, expected.g, expected.b])
            (channel * 255).round(),
        ];
        for (var c = 0; c < 3; c++) {
          expect(
            actual[c],
            closeTo(want[c], 3),
            reason: '$reason: got $actual, want $want',
          );
        }
      }

      final c = light().colors;
      expectPixel(
        7,
        bottom - 6,
        c.neutralStrokeAccessible,
        'below the diagonal: the bottom colour, #616161',
      );
      expectPixel(
        4,
        bottom - 8,
        c.neutralStroke1,
        'above the diagonal: the side colour, #d1d1d1',
      );
    });

    testWidgets('the focus rule is the compound brand stroke, 2px, on every '
        'appearance', (tester) async {
      for (final entry in styleNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Focus',
        });
        final rule = variant.part('InFocus');

        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          FluentTextarea(key: key, appearance: entry.key, focusNode: node),
        );
        node.requestFocus();
        await tester.pumpAndSettle();

        expect(focusRuleOf(tester).color, rule.fill, reason: entry.value);
        expect(
          tester.getSize(find.byKey(fluentTextareaFocusUnderlineKey)).height,
          rule.size.height,
          reason: '${entry.value}: focus rule thickness',
        );
        expect(
          focusRuleOf(tester).borderRadius,
          BorderRadius.only(
            bottomLeft: rule.radius!.bottomLeft,
            bottomRight: rule.radius!.bottomRight,
          ),
          reason: '${entry.value}: focus rule corners',
        );
      }
    });

    testWidgets('error paints colorPaletteRedBorder2 on all four sides', (
      tester,
    ) async {
      // Figma and the status token say `#c50f1f`; upstream renders
      // `colorPaletteRedBorder2`, `#d13438`, at rest and on hover.
      final danger = light().colors.palette.stroke2Rest(
        FluentPaletteFamily.red,
      )!;
      expect(danger, const Color(0xFFD13438));
      for (final entry in styleNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Error',
        });
        await pump(
          tester,
          FluentTextarea(key: key, appearance: entry.key, invalid: true),
        );
        await tester.pumpAndSettle();

        expect(
          borderOf(tester).borderColor,
          danger,
          reason: '${entry.value}: error border',
        );
        expect(
          borderOf(tester).bottomBorderColor,
          isNull,
          reason: '${entry.value}: the red runs round the bottom too',
        );
        expect(
          surfaceOf(tester).color,
          variant.part('Contents').fill,
          reason: '${entry.value}: error keeps its own fill',
        );
      }
      final style = resolveFluentTextareaStyle(
        resolveFluentTextareaState(invalid: true),
        light(),
      );
      expect(
        style.borderColor!.resolve(const <WidgetState>{WidgetState.hovered}),
        danger,
        reason: 'red holds on hover',
      );

      // The palette knows nothing of high contrast; the status token does.
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      expect(
        resolveFluentTextareaStyle(
          resolveFluentTextareaState(invalid: true),
          hc,
        ).borderColor!.resolve(const <WidgetState>{}),
        hc.colors.statusDangerBorder2,
      );
    });

    test('focus drops the error border back to the focus ramp', () {
      // `useTextareaStyles.styles.ts` scopes `colorPaletteRedBorder2` to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // textarea is drawn like any other focused one and the brand bar is what
      // marks it.
      final theme = light();
      final style = resolveFluentTextareaStyle(
        resolveFluentTextareaState(invalid: true, focused: true),
        theme,
      );

      expect(
        style.borderColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralStroke1Pressed,
      );
      expect(
        style.underlineColor!.resolve(const <WidgetState>{}),
        theme.colors.compoundBrandStroke,
      );
    });

    test('read only is styled exactly like an editable field', () {
      // Upstream passes `readOnly` to the `<textarea>` and styles nothing:
      // `readonly` renders pixel-identical to `rest`, and `readonly_focused` to
      // `focused`. Figma's `State=Read only` greys the chrome instead.
      final theme = light();
      const stateSets = <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.hovered},
        <WidgetState>{WidgetState.hovered, WidgetState.pressed},
      ];
      for (final appearance in FluentTextareaAppearance.values) {
        for (final focused in <bool>[false, true]) {
          FluentTextareaStyle style({required bool readOnly}) =>
              resolveFluentTextareaStyle(
                resolveFluentTextareaState(
                  appearance: appearance,
                  focused: focused,
                  readOnly: readOnly,
                ),
                theme,
              );
          final editable = style(readOnly: false);
          final readOnly = style(readOnly: true);
          for (final states in stateSets) {
            final reason = '${appearance.name} focused: $focused $states';
            expect(
              readOnly.backgroundColor!.resolve(states),
              editable.backgroundColor!.resolve(states),
              reason: '$reason: fill',
            );
            expect(
              readOnly.borderColor!.resolve(states),
              editable.borderColor!.resolve(states),
              reason: '$reason: border',
            );
            expect(
              readOnly.underlineColor?.resolve(states),
              editable.underlineColor?.resolve(states),
              reason: '$reason: bottom',
            );
            expect(
              readOnly.focusUnderlineColor?.resolve(states),
              editable.focusUnderlineColor?.resolve(states),
              reason: '$reason: focus bar',
            );
            expect(
              readOnly.foregroundColor!.resolve(states),
              editable.foregroundColor!.resolve(states),
              reason: '$reason: text',
            );
          }
        }
      }
    });

    testWidgets('disabled erases the appearance and the focus bar', (
      tester,
    ) async {
      for (final entry in styleNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Disabled',
        });
        final contents = variant.part('Contents');
        await pump(
          tester,
          FluentTextarea(key: key, appearance: entry.key, enabled: false),
        );
        await tester.pumpAndSettle();

        final reason = entry.value;
        expect(surfaceOf(tester).color!.a, contents.fill!.a, reason: reason);
        expect(borderOf(tester).borderColor, contents.stroke, reason: reason);
        expect(borderOf(tester).bottomBorderColor, isNull, reason: reason);
        expect(
          find.byKey(fluentTextareaFocusUnderlineKey),
          findsNothing,
          reason: '$reason: upstream drops the ::after bar',
        );
      }
    });

    test('a disabled field shows the not-allowed cursor', () {
      final style = resolveFluentTextareaStyle(
        resolveFluentTextareaState(enabled: false),
        light(),
      );
      expect(
        style.mouseCursor!.resolve(const <WidgetState>{WidgetState.disabled}),
        SystemMouseCursors.forbidden,
      );
    });

    testWidgets('the caret is 1px, in the text colour', (tester) async {
      await pump(tester, const FluentTextarea(key: key));
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorWidth, FluentStroke.thin);
      expect(editable.cursorColor, light().colors.neutralForeground1);
    });

    testWidgets('read only keeps full-contrast text, disabled does not', (
      tester,
    ) async {
      final theme = light();
      final readOnly = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Read only',
      });
      final disabled = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Disabled',
      });
      expect(
        readOnly.text!.tokens['fills']!.single,
        'Neutral/Foreground/1/Rest',
      );
      expect(
        disabled.text!.tokens['fills']!.single,
        'Neutral/Foreground/Disabled/Rest',
      );

      Color foreground({required bool enabled}) =>
          resolveFluentTextareaStyle(
            resolveFluentTextareaState(enabled: enabled, readOnly: enabled),
            theme,
          ).foregroundColor!.resolve(<WidgetState>{
            if (!enabled) WidgetState.disabled,
          })!;

      expect(foreground(enabled: true), theme.colors.neutralForeground1);
      expect(
        foreground(enabled: false),
        theme.colors.neutralForegroundDisabled,
      );
    });
  });

  group('motion', () {
    // useTextareaStyles.styles.ts: the `::after` rule transitions `transform`
    // at durationUltraFast, and `:focus-within::after` at durationNormal. The
    // curve tokens sit in `transitionDelay`, which the browser drops, so Chrome
    // runs both on CSS `ease` — `document.getAnimations()` on the live
    // storybook reports exactly that.
    test('the two specs are the ones upstream renders', () {
      expect(fluentTextareaFocusUnderlineEnter.duration, FluentDuration.normal);
      expect(fluentTextareaFocusUnderlineEnter.curve, FluentCssCubic.ease);
      expect(
        fluentTextareaFocusUnderlineExit.duration,
        FluentDuration.ultraFast,
      );
      expect(fluentTextareaFocusUnderlineExit.curve, FluentCssCubic.ease);
    });

    testWidgets('the focus rule scales in over 200ms and back out over 50', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, FluentTextarea(key: key, focusNode: node));
      await tester.pumpAndSettle();
      expect(focusRuleScaleOf(tester), 0);

      node.requestFocus();
      // Two pumps: the first applies the focus change, the second is the frame
      // that rebuilds with focused: true and starts the tween.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = focusRuleScaleOf(tester);
      expect(
        midway,
        allOf(greaterThan(0.0), lessThan(1.0)),
        reason: 'must be mid-tween, not instant',
      );
      await tester.pumpAndSettle();
      expect(focusRuleScaleOf(tester), 1);

      node.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(
        focusRuleScaleOf(tester),
        allOf(greaterThan(0.0), lessThan(1.0)),
        reason: 'the exit is a tween too',
      );
      // 60ms is past the 50ms exit but nowhere near the 200ms entrance, which
      // is what pins the asymmetry rather than just "it animates".
      await tester.pump(const Duration(milliseconds: 35));
      expect(focusRuleScaleOf(tester), 0);
    });

    testWidgets('reduced motion snaps the focus rule in', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentTextarea(key: key, focusNode: node),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusRuleScaleOf(tester), 1);
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
        const FluentTextareaTheme(
          style: FluentTextareaStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(themed),
          ),
          child: FluentTextarea(
            key: key,
            style: FluentTextareaStyle(
              backgroundColor: WidgetStatePropertyAll<Color?>(explicit),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        const FluentTextareaTheme(
          style: FluentTextareaStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(themed),
          ),
          child: FluentTextarea(key: key),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTextarea(
          key: key,
          style: FluentTextareaStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        surfaceOf(tester).color,
        light().colors.neutralBackground1,
        reason: 'overriding radius must not drop the fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentTextarea(
            const FluentTextareaBaseState(
              enabled: true,
              readOnly: false,
              invalid: false,
              focused: false,
            ),
            FluentTextareaStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
              borderWidth: FluentStroke.thin,
              borderColor: const Color(0xFF0000FF),
            ),
            const <WidgetState>{},
            const SizedBox(height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, mine);
      expect(surfaceOf(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentTextareaState(
        appearance: FluentTextareaAppearance.filledDarker,
      );
      final theme = light();
      final adjusted = resolveFluentTextareaStyle(
        state,
        theme,
      ).merge(FluentTextareaStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentTextarea(
            state,
            adjusted,
            const <WidgetState>{},
            const SizedBox(height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, theme.colors.neutralBackground3);
      expect(surfaceOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the textarea', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralBackground3: magenta},
            child: Center(
              child: SizedBox(
                width: 280,
                child: FluentTextarea(
                  key: key,
                  appearance: FluentTextareaAppearance.filledDarker,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in FluentTextareaAppearance.values) {
        await pump(
          tester,
          FluentTextarea(key: key, appearance: appearance),
          theme: theme,
        );
        await tester.pumpAndSettle();
        // transparentStroke becomes canvasText in high contrast, so the border
        // that is invisible in light must be opaque here — otherwise a filled
        // textarea has no outline at all.
        expect(
          borderOf(tester).borderColor!.a,
          1.0,
          reason: '${appearance.name}: border must be opaque in high contrast',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('typing runs through onChanged and keeps newlines', (
      tester,
    ) async {
      final changes = <String>[];
      await pump(tester, FluentTextarea(key: key, onChanged: changes.add));
      await tester.enterText(find.byType(EditableText), 'one\ntwo');
      await tester.pump();
      expect(changes.last, 'one\ntwo');
    });

    testWidgets('tapping focuses the field', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, FluentTextarea(key: key, focusNode: node));
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    });

    testWidgets(
      'a mouse click on the padding focuses the field',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        // The padding belongs to the `<textarea>` upstream, so Chrome focuses
        // it from there. `tester.tap` hits the centre, which is text.
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(tester, FluentTextarea(key: key, focusNode: node));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.down(
          tester.getTopLeft(find.byKey(key)) + const Offset(6, 4),
        );
        await mouse.up();
        await tester.pumpAndSettle();
        expect(node.hasFocus, isTrue);
      },
    );

    testWidgets('a one-row field still wraps and keeps newlines', (
      tester,
    ) async {
      // `rows="1"` is still a `<textarea>`. EditableText's `maxLines: 1` is a
      // single-line input that strips newlines, so the field must not get it.
      final changes = <String>[];
      await pump(
        tester,
        FluentTextarea(key: key, minLines: 1, onChanged: changes.add),
      );
      await tester.enterText(find.byType(EditableText), 'one\ntwo');
      await tester.pump();
      expect(changes.last, 'one\ntwo');
    });

    testWidgets('onSubmitted fires from the keyboard action', (tester) async {
      String? submitted;
      await pump(
        tester,
        FluentTextarea(
          key: key,
          minLines: 1,
          maxLines: 1,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => submitted = value,
        ),
      );
      await tester.enterText(find.byType(EditableText), 'done');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(submitted, 'done');
    });

    testWidgets('disabled is a real state, not a treatment', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final changes = <String>[];
      await pump(
        tester,
        FluentTextarea(
          key: key,
          focusNode: node,
          enabled: false,
          onChanged: changes.add,
        ),
      );
      await tester.pumpAndSettle();
      final theme = light();

      expect(node.canRequestFocus, isFalse, reason: 'must refuse focus');
      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse);

      // And it must not adopt the hover ramp either.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(borderOf(tester).borderColor, theme.colors.neutralStrokeDisabled);
      expect(changes, isEmpty);
    });

    testWidgets('read only refuses edits but keeps focus and selection', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'locked');
      addTearDown(controller.dispose);
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentTextarea(
          key: key,
          controller: controller,
          focusNode: node,
          readOnly: true,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(node.hasFocus, isTrue, reason: 'read only stays focusable');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .enableInteractiveSelection,
        isTrue,
        reason: 'read only content must still be selectable',
      );
      expect(controller.text, 'locked');
    });

    testWidgets('the placeholder shows only while the field is empty', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        FluentTextarea(
          key: key,
          controller: controller,
          placeholder: 'Say something',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Say something'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Say something')).style!.color,
        light().colors.neutralForeground4,
      );

      await tester.enterText(find.byType(EditableText), 'x');
      await tester.pumpAndSettle();
      expect(find.text('Say something'), findsNothing);
    });

    testWidgets('semantics announce a read-only, labelled text field', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTextarea(key: key, semanticLabel: 'Notes', readOnly: true),
      );
      final wrapper = tester.getSemantics(find.byKey(key));
      expect(
        wrapper,
        isSemantics(
          label: 'Notes',
          isReadOnly: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );

      // The editable itself is a semantics boundary, so it keeps its own node
      // under the wrapper rather than merging into it.
      final children = <SemanticsNode>[];
      wrapper.visitChildren((node) {
        children.add(node);
        return true;
      });
      expect(
        children.single,
        isSemantics(isTextField: true, isMultiline: true, isReadOnly: true),
      );
    });

    testWidgets('a hard character cap is enforced', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        FluentTextarea(key: key, controller: controller, maxLength: 4),
      );
      await tester.enterText(find.byType(EditableText), 'abcdefgh');
      await tester.pump();
      expect(controller.text, 'abcd');
    });
  });

  group('selection controls', () {
    test('handles anchor to the text, not to their own centre', () {
      final controls = fluentTextSelectionControls;
      expect(
        controls.getHandleSize(20),
        const Size.square(FluentTextSelectionControls.handleSize),
      );
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.left, 20),
        const Offset(FluentTextSelectionControls.handleSize, 0),
      );
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.right, 20),
        Offset.zero,
      );
      expect(
        controls.getHandleAnchor(TextSelectionHandleType.collapsed, 20),
        const Offset(FluentTextSelectionControls.handleSize / 2, 0),
      );
    });

    testWidgets('the handle paints in the brand tone', (tester) async {
      final controls = fluentTextSelectionControls;
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Builder(
            builder: (context) => controls.buildHandle(
              context,
              TextSelectionHandleType.left,
              20,
              () {},
            ),
          ),
        ),
      );
      final decoration =
          tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
              as BoxDecoration;
      expect(decoration.color, light().colors.compoundBrandStroke);
      expect(decoration.shape, BoxShape.circle);
    });

    bool handlesShown(WidgetTester tester) =>
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .selectionOverlay
            ?.handlesAreVisible ??
        false;

    testWidgets(
      'a mouse never shows the touch handles',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        final controller = TextEditingController(text: 'hello world again');
        addTearDown(controller.dispose);
        await pump(tester, FluentTextarea(key: key, controller: controller));
        final text = tester.getTopLeft(find.byType(EditableText));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);

        // Click.
        await mouse.down(text + const Offset(20, 10));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(controller.selection.isCollapsed, isTrue);
        expect(handlesShown(tester), isFalse, reason: 'click');

        // Drag.
        await mouse.down(text + const Offset(4, 10));
        await tester.pump();
        await mouse.moveTo(text + const Offset(80, 10));
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        expect(controller.selection.isCollapsed, isFalse);
        expect(handlesShown(tester), isFalse, reason: 'drag');

        // Double-click.
        await tester.pump(const Duration(milliseconds: 500));
        await mouse.down(text + const Offset(20, 10));
        await mouse.up();
        await tester.pump(const Duration(milliseconds: 50));
        await mouse.down(text + const Offset(20, 10));
        await mouse.up();
        await tester.pumpAndSettle();
        expect(controller.selection.textInside(controller.text), 'hello');
        expect(handlesShown(tester), isFalse, reason: 'double-click');
      },
    );

    testWidgets('a touch long-press shows the handles', (tester) async {
      final controller = TextEditingController(text: 'hello world again');
      addTearDown(controller.dispose);
      await pump(tester, FluentTextarea(key: key, controller: controller));
      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(20, 10),
      );
      await tester.pumpAndSettle();
      expect(handlesShown(tester), isTrue);
    });

    testWidgets('the field wires them in', (tester) async {
      await pump(tester, const FluentTextarea(key: key));
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .selectionControls,
        isA<FluentTextSelectionControls>(),
      );
    });
  });
  // One shape, one implementation: the focus bar is `FluentInputFocusUnderline`
  // (input.dart), which is where the `max(thickness, radius)` + clip trick that
  // keeps a 4px corner on a 2px bar lives.
  testWidgets('the focus bar comes from the shared primitive', (tester) async {
    await pump(tester, const FluentTextarea(key: key));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(FluentInputFocusUnderline),
      ),
      findsOneWidget,
      reason: 'one shape, one implementation — see input.dart',
    );
  });
}
