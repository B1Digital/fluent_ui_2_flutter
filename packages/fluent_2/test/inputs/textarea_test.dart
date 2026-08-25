import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTextarea` is the package's first text input, so these tests cover the
/// editing contract as well as the token table: focus, keyboard, selection and
/// the two independent bottom rules.
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
  /// subtree, which is the one carrying the fill and the four-sided border.
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

  ColoredBox? restingRuleOf(WidgetTester tester) {
    final found = find.byKey(fluentTextareaUnderlineKey);
    return found.evaluate().isEmpty ? null : tester.widget<ColoredBox>(found);
  }

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

  EdgeInsets paddingOf(WidgetTester tester) => tester
      .widget<Padding>(
        find
            .descendant(of: find.byKey(key), matching: find.byType(Padding))
            .first,
      )
      .padding
      .resolve(TextDirection.ltr);

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

  group('pixel fidelity against Figma', () {
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

    test('Figma has no Resize axis, so neither does the widget', () {
      // The brief for this component named a fourth `Resize` axis. The file has
      // three. Recorded as a test so a future reader does not go looking for a
      // resize handle that was never specified.
      expect(spec.properties.keys, <String>['Style', 'Size', 'State']);
    });

    testWidgets('inset and type ramp match every size', (tester) async {
      for (final size in FluentTextareaSize.values) {
        final variant = spec.variant({
          'Style': 'Outline',
          'Size': sizeNames[size]!,
          'State': 'Rest',
        });
        // Figma splits the inset across two frames; the widget applies the sum.
        final outer = variant.part('Contents').padding!;
        final inner = variant.part('.Text').padding!;

        await pump(tester, FluentTextarea(key: key, size: size));
        await tester.pumpAndSettle();

        final padding = paddingOf(tester);
        expect(
          padding.left,
          outer.left + inner.left,
          reason: '${size.name}: padding.left',
        );
        expect(
          padding.right,
          outer.right + inner.right,
          reason: '${size.name}: padding.right',
        );
        expect(
          padding.top,
          outer.top + inner.top,
          reason: '${size.name}: padding.top',
        );
        expect(
          padding.bottom,
          outer.bottom + inner.bottom,
          reason: '${size.name}: padding.bottom',
        );

        final text = variant.text!;
        final resolved = resolveFluentTextareaStyle(
          resolveFluentTextareaState(size: size),
          light(),
        ).textStyle!.resolve(const <WidgetState>{})!;
        expect(resolved.fontSize, text.fontSize, reason: '${size.name}: size');
        expect(
          resolved.height! * resolved.fontSize!,
          text.lineHeight,
          reason: '${size.name}: line height',
        );
        expect(
          surfaceOf(tester).borderRadius,
          variant.radius,
          reason: '${size.name}: radius',
        );
      }
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
          // Figma paints no stroke on the filled appearances; we paint the
          // transparent token instead so high contrast can outline them.
          expect(
            surfaceOf(tester).border!.top.color.a,
            0,
            reason: '${entry.value}: border must be invisible in light',
          );
        } else {
          expect(
            surfaceOf(tester).border!.top.color,
            stroke,
            reason: '${entry.value}: resting border',
          );
        }
      }
    });

    testWidgets('the outline border walks its ramp on hover and press', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, const FluentTextarea(key: key));
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).border!.top.color,
        spec
            .variant({'Style': 'Outline', 'Size': 'Medium', 'State': 'Rest'})
            .part('Contents')
            .stroke,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).border!.top.color,
        theme.colors.neutralStroke1Hover,
        reason: 'hover',
      );
      expect(
        surfaceOf(tester).border!.top.color,
        spec
            .variant({'Style': 'Outline', 'Size': 'Medium', 'State': 'Hover'})
            .part('Contents')
            .stroke,
      );

      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        surfaceOf(tester).border!.top.color,
        spec
            .variant({'Style': 'Outline', 'Size': 'Medium', 'State': 'Pressed'})
            .part('Contents')
            .stroke,
        reason: 'pressed',
      );
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('only Outline draws the resting bottom rule', (tester) async {
      for (final entry in styleNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'State': 'Rest',
        });
        await pump(tester, FluentTextarea(key: key, appearance: entry.key));
        await tester.pumpAndSettle();

        final drawn = variant.parts.any((p) => p.name == 'Thin underline');
        expect(
          restingRuleOf(tester) != null,
          drawn,
          reason: '${entry.value}: resting rule',
        );
        if (drawn) {
          expect(
            restingRuleOf(tester)!.color,
            variant.part('Thin underline').fill,
            reason: '${entry.value}: rule colour',
          );
        }
      }
    });

    testWidgets('the bottom rule thickens on press, as Figma has it', (
      tester,
    ) async {
      final rest = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Rest',
      });
      final pressed = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Pressed',
      });
      expect(rest.part('Thin underline').size.height, 1);
      expect(pressed.part('Thick underline').size.height, 2);

      await pump(tester, const FluentTextarea(key: key));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(fluentTextareaUnderlineKey)).height,
        rest.part('Thin underline').size.height,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(fluentTextareaUnderlineKey)).height,
        pressed.part('Thick underline').size.height,
      );
      expect(
        restingRuleOf(tester)!.color,
        pressed.part('Thick underline').fill,
      );
      await mouse.up();
      await tester.pumpAndSettle();
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

    testWidgets('error paints the danger border and drops the bottom rule', (
      tester,
    ) async {
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
          surfaceOf(tester).border!.top.color,
          variant.part('Contents').stroke,
          reason: '${entry.value}: error border',
        );
        expect(
          surfaceOf(tester).color,
          variant.part('Contents').fill,
          reason: '${entry.value}: error keeps its own fill',
        );
        expect(restingRuleOf(tester), isNull, reason: entry.value);
      }
      expect(
        resolveFluentTextareaStyle(
          resolveFluentTextareaState(invalid: true),
          light(),
        ).borderColor!.resolve(const <WidgetState>{}),
        light().colors.statusDangerBorder2,
      );
    });

    test('focus drops the error border back to the resting ramp', () {
      // `useTextareaStyles.styles.ts` scopes `colorPaletteRedBorder2` to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // textarea is drawn like any other focused one and the brand rule is what
      // marks it. Figma cannot disagree: Error and Focus are two values of a
      // single `State` axis, so no variant is both.
      final theme = light();
      final style = resolveFluentTextareaStyle(
        resolveFluentTextareaState(invalid: true, focused: true),
        theme,
      );

      expect(
        style.borderColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralStroke1,
        reason: 'focused invalid border falls back to Neutral/Stroke/1/Rest',
      );
      expect(
        style.underlineColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralStrokeAccessible,
        reason: 'and the resting rule comes back with it',
      );
    });

    testWidgets('disabled and read only erase the appearance', (tester) async {
      for (final entry in styleNames.entries) {
        for (final readOnly in <bool>[false, true]) {
          final variant = spec.variant({
            'Style': entry.value,
            'Size': 'Medium',
            'State': readOnly ? 'Read only' : 'Disabled',
          });
          final contents = variant.part('Contents');
          await pump(
            tester,
            FluentTextarea(
              key: key,
              appearance: entry.key,
              enabled: readOnly,
              readOnly: readOnly,
            ),
          );
          await tester.pumpAndSettle();

          final reason = '${entry.value} ${variant.props['State']}';
          expect(surfaceOf(tester).color!.a, contents.fill!.a, reason: reason);
          expect(
            surfaceOf(tester).border!.top.color,
            contents.stroke,
            reason: reason,
          );
          expect(restingRuleOf(tester), isNull, reason: reason);
        }
      }
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
            resolveFluentTextareaState(enabled: enabled, readOnly: !enabled),
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

    testWidgets('a medium field is two lines tall, matching the 52px frame', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Rest',
      });
      await pump(tester, const FluentTextarea(key: key));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)).height, variant.size.height);
    });
  });

  group('motion', () {
    // Verified in useTextareaStyles.styles.ts: the `::after` rule transitions
    // `transform` at durationUltraFast/curveAccelerateMid, and
    // `:focus-within::after` at durationNormal/curveDecelerateMid.
    test('the two specs are the ones upstream declares', () {
      expect(fluentTextareaFocusUnderlineEnter.duration, FluentDuration.normal);
      expect(
        fluentTextareaFocusUnderlineEnter.curve,
        FluentCurve.decelerateMid,
      );
      expect(
        fluentTextareaFocusUnderlineExit.duration,
        FluentDuration.ultraFast,
      );
      expect(fluentTextareaFocusUnderlineExit.curve, FluentCurve.accelerateMid);
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
          surfaceOf(tester).border,
          isNotNull,
          reason: '${appearance.name}: border',
        );
        expect(
          surfaceOf(tester).border!.top.color.a,
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
      expect(
        surfaceOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );
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
