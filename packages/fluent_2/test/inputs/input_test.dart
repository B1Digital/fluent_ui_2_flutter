import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentInput` is the first `EditableText`-based component in the package, so
/// these tests cover the text plumbing as well as the token tables: the
/// `TextSelectionGestureDetectorBuilder` wiring, the two-direction focus-bar
/// animation, and the Figma `Input` set variant by variant.
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

  Future<void> pump(
    WidgetTester tester,
    Widget input, {
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
      home: Center(child: SizedBox(width: 280, child: input)),
    ),
  );

  Iterable<BoxDecoration> decorations(WidgetTester tester, Finder of) => tester
      .widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>();

  /// The field's own box: the only decoration carrying the full corner radius.
  /// The bottom rule and the focus bar round their two bottom corners only.
  BoxDecoration boxOf(WidgetTester tester) => decorations(
    tester,
    find.byKey(key),
  ).firstWhere((d) => d.borderRadius == FluentRadius.allMedium);

  /// The bottom rule, or null when the appearance draws none.
  BoxDecoration? ruleOf(WidgetTester tester) {
    final bar = decorations(
      tester,
      find.byType(FluentInputFocusUnderline),
    ).toSet();
    for (final decoration in decorations(tester, find.byKey(key))) {
      if (bar.contains(decoration)) continue;
      if (decoration.borderRadius != FluentRadius.allMedium) return decoration;
    }
    return null;
  }

  /// The bottom rule's thickness, read off the `Positioned` that places it.
  double ruleHeight(WidgetTester tester) => tester
      .widgetList<Positioned>(
        find.descendant(of: find.byKey(key), matching: find.byType(Positioned)),
      )
      .first
      .height!;

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

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('input');

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

        // Figma splits the horizontal inset across two frames: the root inset
        // on `Icon-Text-stack` and the field's own on `.Text`.
        final root = variant.part('Icon-Text-stack').padding!.left;
        final field = variant.part('.Text').padding!.left;
        final paddings = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .map((p) => p.padding.resolve(TextDirection.ltr))
            .toList();
        expect(paddings.first.left, root, reason: '${size.name}: root inset');
        expect(paddings[1].left, field, reason: '${size.name}: field inset');

        final style = tester
            .widget<EditableText>(find.byType(EditableText))
            .style;
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

        final box = boxOf(tester);
        expectFill(box.color, contents.fill, '${entry.value}: fill');

        if (contents.strokeWidth == 0) {
          expect(
            box.border,
            isNull,
            reason: '${entry.value}: Figma paints no box border',
          );
        } else {
          expect(box.border, isNotNull, reason: '${entry.value}: border');
          expect(
            box.border!.top.width,
            contents.strokeWidth,
            reason: '${entry.value}: border width',
          );
          expectFill(
            box.border!.top.color,
            contents.stroke,
            '${entry.value}: border colour (token '
            '${contents.token('strokes')})',
          );
        }
      }
    });

    testWidgets('the bottom rule follows the accessible ramp', (tester) async {
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
          ruleOf(tester)!.color,
          rest.part('Thin underline').fill,
          '${appearance.name}: resting rule '
          '(${rest.part('Thin underline').token('fills')})',
        );
        expect(ruleHeight(tester), 1, reason: '${appearance.name}: rule width');

        // Pressed swaps `Thin underline` for `Thick underline`, 2px, in
        // Neutral/Stroke/Accessible/Pressed.
        final pressed = spec.variant({
          'Style': appearanceNames[appearance]!,
          'State': 'Pressed',
          'Size': 'Medium',
        });
        final gesture = await tester.press(find.byKey(key));
        await tester.pump();
        expectFill(
          ruleOf(tester)!.color,
          pressed.part('Thick underline').fill,
          '${appearance.name}: pressed rule',
        );
        expect(
          ruleHeight(tester),
          pressed.part('Thick underline').size.height,
          reason: '${appearance.name}: pressed rule width',
        );
        await gesture.up();
        await tester.pump();
      }
    });

    testWidgets('the filled appearances draw no bottom rule', (tester) async {
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
        expect(ruleOf(tester), isNull, reason: appearance.name);
      }
    });

    testWidgets('hover moves the outline border and its rule together', (
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
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expectFill(
        boxOf(tester).border!.top.color,
        variant.part('Contents').stroke,
        'hover border (${variant.part('Contents').token('strokes')})',
      );
      expectFill(
        ruleOf(tester)!.color,
        variant.part('Thin underline').fill,
        'hover rule',
      );
    });

    testWidgets('error strokes the whole box in the danger token', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'State': 'Error',
          'Size': 'Medium',
        });

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            appearance: entry.key,
            error: true,
          ),
        );

        final contents = variant.part('Contents');
        if (contents.strokeWidth != 0) {
          expectFill(
            boxOf(tester).border!.top.color,
            contents.stroke,
            '${entry.value}: error border '
            '(${contents.token('strokes')})',
          );
        } else {
          // Underline carries the danger colour on its rule instead.
          expectFill(
            ruleOf(tester)!.color,
            variant.part('Thin underline').fill,
            '${entry.value}: error rule',
          );
        }
      }
    });

    testWidgets('focus drops the error border back to the resting ramp', (
      tester,
    ) async {
      // `useInputStyles.styles.ts` scopes the danger colour to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // field is drawn like any other focused one and the brand bar is what
      // marks it. Figma has nothing to say here: Error and Focus are two values
      // of a single `State` axis, so no variant is both.
      final resting = spec.variant({
        'Style': 'Outline',
        'State': 'Focus',
        'Size': 'Medium',
      });
      // Figma's Focus variant swaps the `Thin underline` rectangle for
      // `InFocus`; the port draws both, so the rule's resting token comes from
      // the Rest variant.
      final rule = spec.variant({
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
          error: true,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.pumpAndSettle();

      expectFill(
        boxOf(tester).border!.top.color,
        resting.part('Contents').stroke,
        'focused error border falls back to '
        '${resting.part('Contents').token('strokes')}',
      );
      expectFill(
        ruleOf(tester)!.color,
        rule.part('Thin underline').fill,
        'focused error rule falls back to '
        '${rule.part('Thin underline').token('fills')}',
      );

      node.unfocus();
      await tester.pumpAndSettle();
    });

    testWidgets('focus holds the outline border and lifts the filled one', (
      tester,
    ) async {
      // The divergence most likely to be "corrected": React's
      // `outlineInteractive` moves `:focus-within` to Stroke1Pressed, while all
      // twelve Figma Focus variants keep Stroke1Rest. Figma wins.
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
        node.requestFocus();
        await tester.pump();
        await tester.pumpAndSettle();

        expectFill(
          boxOf(tester).border!.top.color,
          variant.part('Contents').stroke,
          '${entry.value}: focus border '
          '(${variant.part('Contents').token('strokes')})',
        );
        expectFill(
          barOf(tester)!.color,
          variant.part('InFocus').fill,
          '${entry.value}: focus bar '
          '(${variant.part('InFocus').token('fills')})',
        );
        node.unfocus();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('disabled and read only share one surface ramp', (
      tester,
    ) async {
      for (final state in <String>['Disabled', 'Read only']) {
        final variant = spec.variant({
          'Style': 'Outline',
          'State': state,
          'Size': 'Medium',
        });

        await pump(
          tester,
          FluentInput(
            key: key,
            controller: controller,
            focusNode: node,
            enabled: state == 'Read only',
            readOnly: state == 'Read only',
          ),
        );

        final contents = variant.part('Contents');
        expectFill(boxOf(tester).color, contents.fill, '$state: fill');
        expectFill(
          boxOf(tester).border!.top.color,
          contents.stroke,
          '$state: border (${contents.token('strokes')})',
        );
      }
    });
  });

  group('motion — verified against useInputStyles.styles.ts', () {
    testWidgets('the focus bar grows in over durationNormal, decelerating', (
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
      final half = scaleXOf(tester);
      expect(
        half,
        greaterThan(0.8),
        reason: 'halfway through a decelerating 200ms transition, not linear',
      );
      expect(half, lessThan(1));

      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleXOf(tester), 1, reason: 'settled at scaleX(1)');
    });

    testWidgets('the focus bar leaves in durationUltraFast, accelerating', (
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
      final half = scaleXOf(tester);
      expect(
        half,
        lessThan(0.3),
        reason: 'halfway through an accelerating 50ms transition',
      );
      expect(half, greaterThan(0));

      await tester.pump(const Duration(milliseconds: 25));
      expect(scaleXOf(tester), 0);
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
        boxOf(tester).border!.top.color,
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
        expect(boxOf(tester).border, isNotNull, reason: appearance.name);
        expect(
          boxOf(tester).border!.top.color.a,
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
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(
        boxOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).style.color,
        theme.colors.neutralForegroundDisabled,
      );
    });

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
