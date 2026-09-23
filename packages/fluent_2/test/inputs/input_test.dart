import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentInput` is the first `EditableText`-based component in the package, so
/// these tests cover the text plumbing as well as the token tables: the
/// `TextSelectionGestureDetectorBuilder` wiring, the two-direction focus-bar
/// animation, and the look of upstream's Input as it renders in Chrome — read
/// off the Figma `Input` set wherever Figma agrees with it.
void main() {
  const key = Key('input');

  const sizeNames = <FluentInputSize, String>{
    FluentInputSize.small: 'Small',
    FluentInputSize.medium: 'Medium',
    FluentInputSize.large: 'Large',
  };
  const appearanceNames = <FluentInputAppearance, String>{
    FluentInputAppearance.outline: 'Outline',
    FluentInputAppearance.underline: 'Underline',
    FluentInputAppearance.filledDarker: 'Filled darker',
    FluentInputAppearance.filledLighter: 'Filled lighter',
  };

  late TextEditingController controller;
  late FocusNode node;

  setUp(() {
    controller = TextEditingController();
    node = FocusNode();
  });
  tearDown(() {
    controller.dispose();
    node.dispose();
  });

  // The MediaQuery is always there, so toggling [reducedMotion] between two
  // pumps updates the same element tree instead of rebuilding the field.
  Future<void> pump(
    WidgetTester tester,
    Widget input, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Center(child: SizedBox(width: 280, child: input)),
    ),
  );

  Iterable<BoxDecoration> decorations(WidgetTester tester, Finder of) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>();

  /// The field's background box: the first decoration under it. The focus bar,
  /// the only other one, is painted after it.
  BoxDecoration boxOf(WidgetTester tester) =>
      decorations(tester, find.byKey(key)).first;

  /// The field's border, read as the tones the painter was handed.
  FluentInputBorderPainter borderOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.painter)
      .whereType<FluentInputBorderPainter>()
      .single;

  FluentInputFocusUnderline? barOf(WidgetTester tester) {
    final found = tester.widgetList<FluentInputFocusUnderline>(
      find.byType(FluentInputFocusUnderline),
    );
    return found.isEmpty ? null : found.first;
  }

  double scaleXOf(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .entry(0, 0);

  /// Moves a real mouse onto the field.
  Future<void> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
  }

  /// Focuses the field and lets the bar finish growing.
  Future<void> focus(WidgetTester tester) async {
    node.requestFocus();
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// Blurs the field and lets the bar finish leaving, so the next pump of a
  /// loop starts from rest: the element — and its focus — survive the pump.
  Future<void> blur(WidgetTester tester) async {
    node.unfocus();
    await tester.pumpAndSettle();
  }

  /// A Fluent transparent token is `#00FFFFFF` in Figma and `rgba(0,0,0,0)` in
  /// core. Both are invisible, so only the alpha is comparable.
  void expectFill(Color? actual, Color? expected, String reason) {
    if (expected == null) return;
    if (expected.a == 0) {
      expect(actual?.a ?? 0, 0, reason: reason);
    } else {
      expect(actual?.toARGB32(), expected.toARGB32(), reason: reason);
    }
  }

  // The oracle is upstream's `useInputStyles.styles.ts` as it renders in Chrome
  // on the live storybook. The Figma fixture supplies the numbers where the two
  // agree; where they do not, the upstream value is asserted directly and the
  // Figma one is noted beside it.
  group('pixel fidelity against upstream', () {
    final spec = loadSpec('input');
    final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 84);
      expect(spec.properties['Style'], <String>[
        'Outline',
        'Filled darker',
        'Filled lighter',
        'Underline',
      ]);
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

    testWidgets('geometry and type ramp match every size', (tester) async {
      // Upstream's `<input>` padding with no slots: `S`, `M` and
      // `calc(M + SNudge)`. Figma binds `Spacing/Horizontal/XXS` on `.Text` at
      // every size, which makes Large 14, and measures from the outer edge,
      // where CSS insets the content by the 1px border.
      const textInset = <FluentInputSize, double>{
        FluentInputSize.small: 8,
        FluentInputSize.medium: 12,
        FluentInputSize.large: 18,
      };
      for (final size in FluentInputSize.values) {
        final variant = spec.variant({
          'Style': 'Outline',
          'State': 'Rest',
          'Size': sizeNames[size]!,
        });

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            size: size,
          ),
        );

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${size.name}: height',
        );
        expect(
          boxOf(tester).borderRadius,
          variant.part('Contents').radius,
          reason: '${size.name}: radius',
        );
        expect(
          tester.getTopLeft(find.byType(EditableText)).dx -
              tester.getTopLeft(find.byKey(key)).dx,
          FluentStroke.thin + textInset[size]!,
          reason: '${size.name}: text left edge, inside the 1px border',
        );

        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(
          editable.cursorWidth,
          FluentStroke.thin,
          reason: "${size.name}: the browser's caret is 1px",
        );
        final style = editable.style;
        expect(
          style.fontSize,
          variant.text!.fontSize,
          reason: '${size.name}: fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          variant.text!.lineHeight,
          reason: '${size.name}: lineHeight',
        );
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'State': 'Rest',
          'Size': 'Medium',
        });
        final contents = variant.part('Contents');

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: entry.key,
          ),
        );

        expectFill(boxOf(tester).color, contents.fill, '${entry.value}: fill');

        final border = borderOf(tester);
        if (contents.strokeWidth == 0) {
          expect(
            border.borderColor,
            isNull,
            reason: '${entry.value}: no top, left or right side',
          );
        } else {
          expect(
            border.borderWidth,
            contents.strokeWidth,
            reason: '${entry.value}: border width',
          );
          expectFill(
            border.borderColor,
            contents.stroke,
            '${entry.value}: border colour (token '
            '${contents.token('strokes')})',
          );
        }
      }
    });

    testWidgets('underline is square, the field and its focus bar both', (
      tester,
    ) async {
      // `underlineInteractive` zeroes the root's radius and the `::after`'s.
      // Figma still binds `Corner-radius/Input/Medium` (4) on Underline and
      // rounds its `InFocus` bar by 1.
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          appearance: FluentInputAppearance.underline,
        ),
      );
      expect(boxOf(tester).borderRadius, BorderRadius.zero);
      expect(borderOf(tester).radius, BorderRadius.zero);
      expect(barOf(tester)!.borderRadius, BorderRadius.zero);
    });

    testWidgets('the bottom border follows the accessible ramp at 1px', (
      tester,
    ) async {
      for (final appearance in <FluentInputAppearance>[
        FluentInputAppearance.outline,
        FluentInputAppearance.underline,
      ]) {
        final rest = spec.variant({
          'Style': appearanceNames[appearance]!,
          'State': 'Rest',
          'Size': 'Medium',
        });

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: appearance,
          ),
        );
        expectFill(
          borderOf(tester).bottomBorderColor,
          rest.part('Thin underline').fill,
          '${appearance.name}: resting bottom border '
          '(${rest.part('Thin underline').token('fills')})',
        );
        expect(
          borderOf(tester).bottomBorderWidth,
          FluentStroke.thin,
          reason: '${appearance.name}: bottom border width',
        );

        // Pressed recolours the bottom border to AccessiblePressed and keeps it
        // 1px. Figma agrees on the colour but swaps `Thin underline` for a 2px
        // `Thick underline`; upstream never thickens it.
        final pressed = spec.variant({
          'Style': appearanceNames[appearance]!,
          'State': 'Pressed',
          'Size': 'Medium',
        });
        final gesture = await tester.press(find.byKey(key));
        await tester.pump();
        expectFill(
          borderOf(tester).bottomBorderColor,
          pressed.part('Thick underline').fill,
          '${appearance.name}: pressed bottom border',
        );
        expect(
          borderOf(tester).bottomBorderWidth,
          FluentStroke.thin,
          reason: '${appearance.name}: pressed bottom border stays 1px',
        );
        await gesture.up();
        await tester.pump();
        await blur(tester);
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
        RepaintBoundary(
          key: boundary,
          child: FluentInput(key: key, controller: controller, focusNode: node),
        ),
      );
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

      expectPixel(
        7,
        bottom - 6,
        light.colors.neutralStrokeAccessible,
        'below the diagonal: the bottom colour, #616161',
      );
      expectPixel(
        4,
        bottom - 8,
        light.colors.neutralStroke1,
        'above the diagonal: the side colour, #d1d1d1',
      );
    });

    testWidgets('the filled appearances have no bottom border of their own', (
      tester,
    ) async {
      for (final appearance in <FluentInputAppearance>[
        FluentInputAppearance.filledDarker,
        FluentInputAppearance.filledLighter,
      ]) {
        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: appearance,
          ),
        );
        expect(
          borderOf(tester).bottomBorderColor,
          isNull,
          reason: '${appearance.name}: the box border runs round all four',
        );
      }
    });

    testWidgets('hover moves the outline border and its bottom together', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Outline',
        'State': 'Hover',
        'Size': 'Medium',
      });

      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      await hover(tester);

      expectFill(
        borderOf(tester).borderColor,
        variant.part('Contents').stroke,
        'hover border (${variant.part('Contents').token('strokes')})',
      );
      expectFill(
        borderOf(tester).bottomBorderColor,
        variant.part('Thin underline').fill,
        'hover bottom border',
      );
    });

    testWidgets('error strokes every side in colorPaletteRedBorder2', (
      tester,
    ) async {
      // Figma's Error column uses `Status/Danger/Stroke/2/Rest` (#c50f1f);
      // upstream's `invalid` rule writes the palette's red, #d13438 in light.
      final danger = light.colors.palette.stroke2Rest(FluentPaletteFamily.red);
      expect(danger, const Color(0xFFD13438));

      for (final appearance in FluentInputAppearance.values) {
        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: appearance,
            error: true,
          ),
        );

        final border = borderOf(tester);
        if (appearance == FluentInputAppearance.underline) {
          expect(border.borderColor, isNull, reason: 'underline: no sides');
        } else {
          expect(
            border.borderColor,
            danger,
            reason: '${appearance.name}: sides',
          );
        }
        expect(
          border.bottomBorderColor ?? border.borderColor,
          danger,
          reason: '${appearance.name}: bottom',
        );
      }
    });

    testWidgets('a focused invalid field takes the focused ramp', (
      tester,
    ) async {
      // `useInputStyles.styles.ts` scopes the danger colour to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // field is drawn like any other focused one. Figma has nothing to say
      // here: Error and Focus are two values of one `State` axis.
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          error: true,
        ),
      );
      await focus(tester);

      expect(borderOf(tester).borderColor, light.colors.neutralStroke1Pressed);
      expect(
        borderOf(tester).bottomBorderColor,
        light.colors.neutralStrokeAccessiblePressed,
      );

      await blur(tester);
    });

    testWidgets('focus moves the outline border to Pressed, hovered or not', (
      tester,
    ) async {
      // `outlineInteractive` writes `:active,:focus-within` as one rule that
      // Griffel sorts after `:hover`, so a focused field shows the Pressed
      // stops, hovered or not. All twelve Figma `Style=Outline, State=Focus`
      // variants keep `Neutral/Stroke/1/Rest` instead.
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      await focus(tester);

      void expectPressed(String when) {
        expect(
          borderOf(tester).borderColor,
          light.colors.neutralStroke1Pressed,
          reason: '$when: sides, #b3b3b3',
        );
        expect(
          borderOf(tester).bottomBorderColor,
          light.colors.neutralStrokeAccessiblePressed,
          reason: '$when: bottom, #4d4d4d',
        );
      }

      expectPressed('focused');
      await hover(tester);
      expectPressed('focused and hovered');

      await blur(tester);
    });

    testWidgets(
      'every mouse button presses the field, the right one included',
      (tester) async {
        // Unlike the Combobox family, Chrome sets `:active` on `.fui-Input`
        // for a right press too (storybook, fresh page per button), so
        // `:focus-within:active::after` turns the bar Pressed for all three.
        await pump(
          tester,
          FluentInput(key: key, controller: controller, focusNode: node),
        );
        for (final button in <int>[
          kPrimaryMouseButton,
          kMiddleMouseButton,
          kSecondaryMouseButton,
        ]) {
          final press = await tester.startGesture(
            tester.getCenter(find.byKey(key)),
            kind: PointerDeviceKind.mouse,
            buttons: button,
          );
          await tester.pump();
          expect(
            borderOf(tester).borderColor,
            light.colors.neutralStroke1Pressed,
            reason: 'button $button: sides',
          );
          expect(
            barOf(tester)!.color,
            light.colors.compoundBrandStrokePressed,
            reason: 'button $button: bar',
          );
          await press.up();
          await press.removePointer();
          await blur(tester);
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      // A CSS `height` sizes the border box, and `::after` sits on its bottom.
      await pump(
        tester,
        SizedBox(
          height: 60,
          child: FluentInput(key: key, controller: controller, focusNode: node),
        ),
      );
      final painted = find.descendant(
        of: find.byKey(key),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
        ),
      );
      final bar = find.byType(FluentInputFocusUnderline);
      expect(tester.getRect(painted).height, 60);
      expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
    });

    testWidgets('a field removed mid-press takes the release quietly', (
      tester,
    ) async {
      // The release still reaches the detached `Listener`, after `dispose`.
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      final press = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await pump(tester, const SizedBox());
      await press.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('focus lifts the filled border and shows the brand bar', (
      tester,
    ) async {
      for (final entry in <FluentInputAppearance, String>{
        FluentInputAppearance.outline: 'Outline',
        FluentInputAppearance.filledLighter: 'Filled lighter',
      }.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'State': 'Focus',
          'Size': 'Medium',
        });

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: entry.key,
          ),
        );
        await focus(tester);

        if (entry.key != FluentInputAppearance.outline) {
          expectFill(
            borderOf(tester).borderColor,
            variant.part('Contents').stroke,
            '${entry.value}: focus border '
            '(${variant.part('Contents').token('strokes')})',
          );
        }
        expectFill(
          barOf(tester)!.color,
          variant.part('InFocus').fill,
          '${entry.value}: focus bar '
          '(${variant.part('InFocus').token('fills')})',
        );
        await blur(tester);
      }
    });

    testWidgets('disabled matches its Figma column', (tester) async {
      final variant = spec.variant({
        'Style': 'Outline',
        'State': 'Disabled',
        'Size': 'Medium',
      });

      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          enabled: false,
        ),
      );

      final contents = variant.part('Contents');
      expectFill(boxOf(tester).color, contents.fill, 'fill');
      final border = borderOf(tester);
      for (final side in <Color?>[
        border.borderColor,
        border.bottomBorderColor,
      ]) {
        expectFill(
          side,
          contents.stroke,
          'every side (${contents.token('strokes')})',
        );
      }
    });

    testWidgets('read only looks exactly like rest', (tester) async {
      // Upstream has no read-only rule: `readOnly` goes straight to the
      // `<input>` and the root keeps every interactive rule. Figma paints its
      // Read only column with the Disabled ramp; upstream wins, so the expected
      // values here are Figma's Rest column.
      final rest = spec.variant({
        'Style': 'Outline',
        'State': 'Rest',
        'Size': 'Medium',
      });

      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          readOnly: true,
        ),
      );

      final contents = rest.part('Contents');
      expectFill(boxOf(tester).color, contents.fill, 'fill');
      expectFill(borderOf(tester).borderColor, contents.stroke, 'sides');
      expectFill(
        borderOf(tester).bottomBorderColor,
        rest.part('Thin underline').fill,
        'bottom',
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        light.colors.neutralForeground1,
        reason: 'the value keeps the ordinary text colour',
      );
    });
  });

  group('motion — measured on the live storybook', () {
    // Upstream's `transitionDelay: curve…` typo leaves every browser on CSS
    // `ease`, solved exactly by [FluentCssCubic.ease]. Chrome's scale 100ms
    // into the entrance is .802403.
    final half = FluentCssCubic.ease.transform(0.5);

    testWidgets('the focus bar grows in over durationNormal on ease', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      await tester.pumpAndSettle();
      expect(scaleXOf(tester), 0, reason: 'unfocused: scaleX(0)');

      node.requestFocus();
      // Two pumps: the focus change lands in a post-frame callback, so the
      // rebuild that starts the transition is the frame after it.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleXOf(tester), closeTo(half, 1e-3));
      expect(half, closeTo(0.802403, 1e-6), reason: "Chrome's measured scale");

      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleXOf(tester), 1, reason: 'settled at scaleX(1)');
    });

    testWidgets('the focus bar leaves in durationUltraFast on ease', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          autofocus: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(scaleXOf(tester), 1);

      node.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(scaleXOf(tester), closeTo(1 - half, 1e-3));

      await tester.pump(const Duration(milliseconds: 25));
      expect(scaleXOf(tester), 0);
    });

    testWidgets('a blur mid-entrance retracts from where the bar is', (
      tester,
    ) async {
      // CSS reversing: a new `ease` transition from the current scale p, over
      // durationUltraFast × p — 40.12ms from .8024, as Chrome measures. Not the
      // entrance curve run backwards.
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final p = scaleXOf(tester);
      expect(p, closeTo(half, 1e-3));

      node.unfocus();
      await tester.pump();
      await tester.pump();
      final exitMicros = FluentDuration.ultraFast.inMicroseconds * p;
      var elapsed = 0;
      for (final ms in <int>[10, 20, 30, 40]) {
        await tester.pump(Duration(milliseconds: ms - elapsed));
        elapsed = ms;
        expect(
          scaleXOf(tester),
          closeTo(
            p * (1 - FluentCssCubic.ease.transform(ms * 1000 / exitMicros)),
            1e-3,
          ),
          reason: '${ms}ms into the retraction',
        );
      }
      expect(
        scaleXOf(tester),
        greaterThan(0),
        reason: 'not done before p·50ms',
      );

      await tester.pump(
        Duration(microseconds: exitMicros.round() - elapsed * 1000),
      );
      expect(scaleXOf(tester), 0, reason: 'done at p·50ms');
    });

    testWidgets('reduced motion applies the focus bar immediately', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(scaleXOf(tester), 1, reason: 'no tween under reduced motion');
    });

    testWidgets('turning reduced motion back off restores the tween', (
      tester,
    ) async {
      final input = FluentInput(
        key: key,
        controller: controller,
        focusNode: node,
      );
      await pump(tester, input, reducedMotion: true);
      await tester.pumpAndSettle();
      await pump(tester, input);
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        scaleXOf(tester),
        closeTo(half, 1e-3),
        reason: 'the durations came back with the setting',
      );
    });

    testWidgets('a disabled field has no focus bar at all', (tester) async {
      // Upstream: `disabled` sets `::after { content: unset }`.
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          enabled: false,
        ),
      );
      expect(barOf(tester), isNull);
    });

    testWidgets('a read-only field keeps its focus bar', (tester) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          readOnly: true,
        ),
      );
      expect(barOf(tester), isNotNull);
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
        FluentInputTheme(
          style: FluentInputStyle.from(backgroundColor: themed),
          child: FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            style: FluentInputStyle.from(backgroundColor: explicit),
          ),
        ),
      );
      expect(boxOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentInputTheme(
          style: FluentInputStyle.from(backgroundColor: themed),
          child: FluentInput(key: key, controller: controller, focusNode: node),
        ),
      );
      expect(boxOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          style: FluentInputStyle.from(borderRadius: FluentRadius.allMedium),
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(boxOf(tester).color, theme.colors.neutralBackground1);
      expect(
        borderOf(tester).borderColor,
        theme.colors.neutralStroke1,
        reason: 'overriding the radius must not drop the stroke token',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      final editableTextKey = GlobalKey<EditableTextState>();
      final base = FluentInputBaseState(
        enabled: true,
        readOnly: false,
        error: false,
        focused: false,
        controller: controller,
        focusNode: node,
        editableTextKey: editableTextKey,
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInput(
            base,
            FluentInputStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allMedium,
              foregroundColor: const Color(0xFF000000),
              cursorColor: const Color(0xFF000000),
              minimumSize: const Size(0, 32),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(boxOf(tester).color, mine);
      expect(tester.getSize(find.byKey(key)).height, 32);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final editableTextKey = GlobalKey<EditableTextState>();
      final state = resolveFluentInputState(
        controller: controller,
        focusNode: node,
        editableTextKey: editableTextKey,
        appearance: FluentInputAppearance.filledDarker,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentInputStyle(
        state,
        theme,
      ).merge(FluentInputStyle.from(minimumSize: const Size(0, 48)));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInput(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(boxOf(tester).color, theme.colors.neutralBackground3);
      expect(tester.getSize(find.byKey(key)).height, 48);
    });
  });

  group('theming', () {
    testWidgets('a subtree override reaches the focus bar', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandStroke: magenta},
            child: Center(
              child: SizedBox(
                width: 280,
                child: FluentInput(
                  key: key,
                  controller: controller,
                  focusNode: node,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(barOf(tester)!.color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      // `transparentStroke` is the field's only outline on the two filled
      // appearances, and it turns opaque in high contrast — a zero-width border
      // there would leave the field with no edge at all.
      for (final appearance in <FluentInputAppearance>[
        FluentInputAppearance.filledDarker,
        FluentInputAppearance.filledLighter,
      ]) {
        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: appearance,
          ),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        );
        final border = borderOf(tester);
        expect(border.borderWidth, FluentStroke.thin, reason: appearance.name);
        expect(
          border.borderColor?.a,
          1.0,
          reason: '${appearance.name}: opaque in high contrast',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('typing reaches the controller and fires onChanged', (
      tester,
    ) async {
      final seen = <String>[];
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          onChanged: seen.add,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'hello');
      await tester.pump();
      expect(controller.text, 'hello');
      expect(seen, <String>['hello']);
    });

    testWidgets('the action key fires onSubmitted', (tester) async {
      String? submitted;
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => submitted = value,
        ),
      );

      await tester.enterText(find.byType(EditableText), 'fluent');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submitted, 'fluent');
    });

    testWidgets('tapping moves focus and places the caret', (tester) async {
      controller.text = 'abcdef';
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );

      await tester.tapAt(tester.getCenter(find.byType(EditableText)));
      await tester.pump();
      expect(node.hasFocus, isTrue, reason: 'a tap must focus the field');
      expect(
        controller.selection.isValid,
        isTrue,
        reason: 'the gesture detector must place a caret',
      );
    });

    testWidgets('obscureText is honoured', (tester) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          obscureText: true,
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
    });

    testWidgets('disabled is a real state, not a treatment', (tester) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          enabled: false,
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
        reason: 'a disabled field refuses edits',
      );

      // A disabled field must not adopt the hover tokens.
      await hover(tester);
      expect(borderOf(tester).borderColor, theme.colors.neutralStrokeDisabled);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        theme.colors.neutralForegroundDisabled,
      );
    });

    testWidgets('the cursor is text, or not-allowed over a disabled field', (
      tester,
    ) async {
      // Chrome: the `<input>` is `text`, and a disabled root and input are
      // both `not-allowed`. `EditableText` installs its own region, so the
      // outer one never showed over the text.
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      for (final enabled in <bool>[true, false]) {
        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            enabled: enabled,
          ),
        );
        await mouse.moveTo(tester.getCenter(find.byType(EditableText)));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          enabled ? SystemMouseCursors.text : SystemMouseCursors.forbidden,
          reason: 'enabled: $enabled',
        );
        await mouse.moveTo(Offset.zero);
        await tester.pump();
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('the placeholder shows only while the value is empty', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          placeholder: const Text('Search'),
        ),
      );
      expect(find.text('Search'), findsOneWidget);
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        tester
            .widgetList<DefaultTextStyle>(
              find.ancestor(
                of: find.text('Search'),
                matching: find.byType(DefaultTextStyle),
              ),
            )
            .first
            .style
            .color,
        theme.colors.neutralForeground4,
        reason: 'the placeholder takes Neutral/Foreground/4/Rest',
      );

      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('the content slots take the icon colour and size', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          contentBefore: const Icon(IconData(0x21)),
          contentAfter: const Icon(IconData(0x22)),
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons, hasLength(2));
      for (final icon in icons) {
        final data = IconTheme.of(tester.element(find.byWidget(icon)));
        expect(data.color, theme.colors.neutralForeground3);
        expect(data.size, FluentSize.size200);
      }
    });

    testWidgets('long press selects a word through the gesture builder', (
      tester,
    ) async {
      controller.text = 'hello world';
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );

      await tester.longPressAt(
        tester.getTopLeft(find.byType(EditableText)) + const Offset(8, 8),
      );
      await tester.pumpAndSettle();
      expect(
        controller.selection.isCollapsed,
        isFalse,
        reason: 'TextSelectionGestureDetectorBuilder must select a word',
      );
    });

    testWidgets('selection handles are wired and take the brand stroke', (
      tester,
    ) async {
      await pump(
        tester,
        FluentInput(key: key, controller: controller, focusNode: node),
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .selectionControls,
        same(fluentTextSelectionControls),
      );
      expect(fluentTextSelectionControls.getHandleSize(20), const Size(16, 16));
      expect(
        fluentTextSelectionControls.getHandleAnchor(
          TextSelectionHandleType.left,
          20,
        ),
        const Offset(16, 0),
      );

      await pump(
        tester,
        Builder(
          builder: (context) => SizedBox(
            key: key,
            child: fluentTextSelectionControls.buildHandle(
              context,
              TextSelectionHandleType.left,
              20,
            ),
          ),
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        decorations(tester, find.byKey(key)).single.color,
        theme.colors.compoundBrandStroke,
      );
    });

    testWidgets('semantics announce a text field', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentInput(
          key: key,
          controller: controller,
          focusNode: node,
          semanticLabel: 'Email',
          readOnly: true,
        ),
      );

      final semantics = tester.getSemantics(find.byKey(key));
      expect(semantics.label, contains('Email'));
      expect(semantics.flagsCollection.isTextField, isTrue);
      expect(semantics.flagsCollection.isReadOnly, isTrue);
      handle.dispose();
    });
  });

  group('focus underline shape', () {
    testWidgets('paints at the radius height and clips back to the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const FluentApp(
          home: Center(
            child: SizedBox(
              width: 200,
              height: 40,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  // Tight on both axes, as the `Positioned(left: 0, right: 0,
                  // bottom: 0, height: 2)` the real callers use is.
                  width: 200,
                  height: FluentStroke.thick,
                  child: FluentInputFocusUnderline(
                    focused: true,
                    color: Color(0xFF0F6CBD),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The layout slot stays 2 tall...
      expect(
        tester.getSize(find.byType(FluentInputFocusUnderline)).height,
        FluentStroke.thick,
      );
      // ...while the painted box is 4, so the 4px radius is not clamped away.
      final painted = tester.getSize(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        painted.height,
        4.0,
        reason: 'Skia halves a 4px radius on a 2px box; React pads then clips',
      );
      expect(
        find.byType(FluentInputFocusUnderline),
        paints..clipRect(),
        reason: 'the extra 2px must be trimmed, not shown',
      );
    });
  });
}
