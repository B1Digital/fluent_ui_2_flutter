import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentCheckbox` is pinned against `test/fixtures/checkbox.json`, extracted
/// from the Figma `Checkbox` component set (node `9061:51474`, 30 variants:
/// Style x Status x State).
///
/// Two things the fixture settles that the React source alone could not:
///
/// * Figma has **no Size axis**. Its single size is [FluentCheckboxSize.medium];
///   [FluentCheckboxSize.large] is upstream-only and no fixture row arbitrates
///   it, so the `large` assertions here stay transcribed from
///   `useCheckboxStyles.styles.ts`.
/// * The indicator is drawn by a [FluentCheckboxGlyphPainter], not composed
///   from widgets, so `expectSpec` cannot read it. The glyph geometry is
///   asserted against a recording canvas instead, against the numbers in the
///   fixture's `parts` array.
///
/// Assertions still marked with an upstream rule are the ones Figma is silent
/// on; everything else names the fixture row it came from.
void main() {
  const key = Key('checkbox');

  Future<void> pump(
    WidgetTester tester,
    Widget checkbox, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: checkbox),
    ),
  );

  /// The indicator box's decoration: fill, border and corner radius.
  BoxDecoration boxOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// The glyph painter. The indicator's tick and mixed square are painted, not
  /// composed, so the resolved colour is read off the painter rather than the
  /// widget tree.
  FluentCheckboxGlyphPainter glyphOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((c) => c.painter)
      .whereType<FluentCheckboxGlyphPainter>()
      .first;

  Future<TestGesture> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
    return mouse;
  }

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('geometry, transcribed from upstream', () {
    testWidgets('the Size axis drives indicator, glyph and root height', (
      tester,
    ) async {
      // useIndicatorBaseClassName: 16px box, fontSize 12px, margin
      // spacingVerticalS/spacingHorizontalS (8). useIndicatorStyles.large: 20px
      // box, fontSize 16px. Root height is the indicator's own margin box.
      const expected = <FluentCheckboxSize, (double, double, double)>{
        FluentCheckboxSize.medium: (16, 12, 32),
        FluentCheckboxSize.large: (20, 16, 36),
      };

      for (final entry in expected.entries) {
        final (box, glyph, height) = entry.value;
        await pump(
          tester,
          FluentCheckbox(
            key: key,
            size: entry.key,
            checked: true,
            onChanged: (_) {},
          ),
        );

        expect(
          tester.getSize(find.byType(CustomPaint).last).width,
          glyph,
          reason: '${entry.key.name}: glyph box',
        );
        expect(
          tester.getSize(find.byType(DecoratedBox).first).width,
          box,
          reason: '${entry.key.name}: indicator box',
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          height,
          reason: '${entry.key.name}: root height',
        );
      }
    });

    testWidgets('the Shape axis drives only the indicator radius', (
      tester,
    ) async {
      // useIndicatorBaseClassName borderRadius borderRadiusSmall; circular
      // overrides it with borderRadiusCircular. Nothing else moves.
      await pump(
        tester,
        FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
      );
      expect(boxOf(tester).borderRadius, FluentRadius.allSmall);

      await pump(
        tester,
        FluentCheckbox(
          key: key,
          shape: FluentCheckboxShape.circular,
          checked: true,
          onChanged: (_) {},
        ),
      );
      expect(boxOf(tester).borderRadius, FluentRadius.allCircular);
    });

    testWidgets('labelPosition orders the row and moves the tight padding', (
      tester,
    ) async {
      // renderCheckbox emits label-then-indicator for 'before'. useLabelStyles
      // gives the label spacingHorizontalXS (4) on the side facing the
      // indicator and spacingHorizontalS (8) on the outside.
      for (final position in FluentCheckboxLabelPosition.values) {
        await pump(
          tester,
          FluentCheckbox(
            key: key,
            labelPosition: position,
            label: const Text('Label'),
            onChanged: (_) {},
          ),
        );

        final box = tester.getTopLeft(find.byType(DecoratedBox).first).dx;
        final label = tester.getTopLeft(find.text('Label')).dx;
        if (position == FluentCheckboxLabelPosition.after) {
          expect(box, lessThan(label), reason: 'after: indicator leads');
        } else {
          expect(label, lessThan(box), reason: 'before: label leads');
        }
      }
    });

    testWidgets('the label keeps the Label medium ramp at every size', (
      tester,
    ) async {
      // useCheckbox passes `size: 'medium'` to Label unconditionally, and the
      // label margin maths uses lineHeightBase300 for both sizes.
      for (final size in FluentCheckboxSize.values) {
        await pump(
          tester,
          FluentCheckbox(
            key: key,
            size: size,
            label: const Text('Label'),
            onChanged: (_) {},
          ),
        );
        final style = resolvedTextStyleOf(tester, of: find.byKey(key));
        expect(style.fontSize, 14, reason: '${size.name}: fontSize');
        expect(style.height! * 14, 20, reason: '${size.name}: lineHeight');
      }
    });

    testWidgets('the border is one thin stroke inside the box', (tester) async {
      // borderWidth strokeWidthThin, box-sizing border-box.
      await pump(
        tester,
        FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
      );
      expect(boxOf(tester).border!.top.width, FluentStroke.thin);
      expect(tester.getSize(find.byType(DecoratedBox).first).width, 16);
    });
  });

  group('the Status axis selects tokens, never computes them', () {
    testWidgets('unchecked: accessible stroke, no fill, no glyph', (
      tester,
    ) async {
      // useRootStyles.unchecked leaves the background var unset and paints the
      // border from colorNeutralStrokeAccessible.
      await pump(
        tester,
        FluentCheckbox(key: key, label: const Text('L'), onChanged: (_) {}),
      );
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeAccessible,
      );
      expect(boxOf(tester).color, light.colors.transparentBackground);
      expect(glyphOf(tester).glyph, FluentCheckboxGlyph.none);
      expect(
        resolvedTextStyleOf(tester, of: find.byKey(key)).color,
        light.colors.neutralForeground3,
        reason: 'useRootBaseClassName colour',
      );
    });

    testWidgets('checked: compound brand fill and inverted tick', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCheckbox(
          key: key,
          checked: true,
          label: const Text('L'),
          onChanged: (_) {},
        ),
      );
      expect(boxOf(tester).color, light.colors.compoundBrandBackground);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.compoundBrandBackground,
      );
      expect(glyphOf(tester).glyph, FluentCheckboxGlyph.checkmark);
      expect(glyphOf(tester).color, light.colors.neutralForegroundInverted);
      expect(
        resolvedTextStyleOf(tester, of: find.byKey(key)).color,
        light.colors.neutralForeground1,
      );
    });

    testWidgets('mixed: compound brand stroke, brand glyph, no fill', (
      tester,
    ) async {
      // useRootStyles.mixed sets only borderColor and the glyph colour — the
      // background var stays unset, so the box is transparent.
      await pump(tester, FluentCheckbox(key: key, onChanged: (_) {}));
      await pump(
        tester,
        FluentCheckbox(
          key: key,
          checked: null,
          label: const Text('L'),
          onChanged: (_) {},
        ),
      );
      expect(boxOf(tester).color, light.colors.transparentBackground);
      expect(boxOf(tester).border!.top.color, light.colors.compoundBrandStroke);
      expect(glyphOf(tester).glyph, FluentCheckboxGlyph.square);
      expect(glyphOf(tester).color, light.colors.compoundBrandForeground1);
    });

    testWidgets('mixed on a circular checkbox draws the circle glyph', (
      tester,
    ) async {
      // useCheckbox: CircleFilled for circular, Square12/16Filled otherwise.
      await pump(
        tester,
        FluentCheckbox(
          key: key,
          checked: null,
          shape: FluentCheckboxShape.circular,
          onChanged: (_) {},
        ),
      );
      expect(glyphOf(tester).glyph, FluentCheckboxGlyph.circle);
    });

    testWidgets('hover and press walk the unchecked stroke ramp', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCheckbox(key: key, label: const Text('L'), onChanged: (_) {}),
      );
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeAccessible,
      );

      final mouse = await hover(tester);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeAccessibleHover,
      );
      expect(
        resolvedTextStyleOf(tester, of: find.byKey(key)).color,
        light.colors.neutralForeground2,
      );

      await mouse.down(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeAccessiblePressed,
      );
      expect(
        resolvedTextStyleOf(tester, of: find.byKey(key)).color,
        light.colors.neutralForeground1,
      );
      await mouse.up();
      await tester.pump();
    });

    testWidgets('hover walks the checked ramp', (tester) async {
      await pump(
        tester,
        FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
      );
      await hover(tester);
      expect(boxOf(tester).color, light.colors.compoundBrandBackgroundHover);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.compoundBrandBackgroundHover,
      );
    });

    testWidgets('hover walks the mixed ramp, glyph included', (tester) async {
      await pump(
        tester,
        FluentCheckbox(key: key, checked: null, onChanged: (_) {}),
      );
      await hover(tester);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.compoundBrandStrokeHover,
      );
      expect(glyphOf(tester).color, light.colors.compoundBrandForeground1Hover);
    });

    testWidgets('disabled replaces the whole status ramp, checked included', (
      tester,
    ) async {
      // useCheckboxStyles_unstable picks rootStyles.disabled INSTEAD of the
      // checked/mixed/unchecked class, so a disabled checked box loses its
      // brand fill entirely rather than dimming it.
      await pump(
        tester,
        const FluentCheckbox(key: key, checked: true, label: Text('L')),
      );
      expect(boxOf(tester).color, light.colors.transparentBackground);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeDisabled,
      );
      expect(glyphOf(tester).color, light.colors.neutralForegroundDisabled);
      expect(
        resolvedTextStyleOf(tester, of: find.byKey(key)).color,
        light.colors.neutralForegroundDisabled,
      );
    });
  });

  group('motion', () {
    testWidgets('there is none: hover lands on the same frame', (tester) async {
      // useCheckboxStyles.styles.ts contains no `transition` of any kind. The
      // indicator is deliberately instant so a click reads as committed.
      await pump(
        tester,
        FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(
        boxOf(tester).color,
        light.colors.compoundBrandBackgroundHover,
        reason: 'no tween: the hover fill is already final',
      );
      expect(
        tester.hasRunningAnimations,
        isFalse,
        reason: 'adding a fade here would contradict upstream',
      );
    });

    testWidgets('toggling checked is instant too', (tester) async {
      await pump(tester, FluentCheckbox(key: key, onChanged: (_) {}));
      await tester.pumpAndSettle();
      await pump(
        tester,
        FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pump();
      expect(boxOf(tester).color, light.colors.compoundBrandBackground);
      expect(tester.hasRunningAnimations, isFalse);
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
        FluentCheckboxTheme(
          style: FluentCheckboxStyle.from(indicatorBackgroundColor: themed),
          child: FluentCheckbox(
            key: key,
            style: FluentCheckboxStyle.from(indicatorBackgroundColor: explicit),
            checked: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(boxOf(tester).color, explicit);

      await pump(
        tester,
        FluentCheckboxTheme(
          style: FluentCheckboxStyle.from(indicatorBackgroundColor: themed),
          child: FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
        ),
      );
      expect(boxOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCheckbox(
          key: key,
          checked: true,
          style: FluentCheckboxStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
          onChanged: (_) {},
        ),
      );
      expect(boxOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        boxOf(tester).color,
        light.colors.compoundBrandBackground,
        reason: 'overriding radius must not drop the brand fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentCheckboxBaseState(
        enabled: true,
        checked: true,
        glyph: FluentCheckboxGlyph.checkmark,
        labelPosition: FluentCheckboxLabelPosition.after,
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentCheckbox(
            base,
            FluentCheckboxStyle.from(
              indicatorBackgroundColor: mine,
              indicatorSize: 24,
              glyphSize: 18,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(boxOf(tester).color, mine);
      expect(tester.getSize(find.byType(DecoratedBox).first).width, 24);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentCheckboxState(checked: true);
      final adjusted = resolveFluentCheckboxStyle(
        state,
        light,
      ).merge(FluentCheckboxStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentCheckbox(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(boxOf(tester).color, light.colors.compoundBrandBackground);
      expect(boxOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the checkbox', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandBackground: magenta},
            child: Center(
              child: FluentCheckbox(key: key, checked: true, onChanged: (_) {}),
            ),
          ),
        ),
      );
      expect(boxOf(tester).color, magenta);
    });

    testWidgets('high contrast keeps every border opaque', (tester) async {
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final checked in <bool?>[false, true, null]) {
        await pump(
          tester,
          FluentCheckbox(key: key, checked: checked, onChanged: (_) {}),
          theme: hc,
        );
        final border = boxOf(tester).border;
        expect(border, isNotNull, reason: 'checked=$checked: border');
        expect(
          border!.top.color.a,
          1.0,
          reason: 'checked=$checked: an invisible box is no box',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('tap and Space report the next value, mixed included', (
      tester,
    ) async {
      // useCheckbox reads the next value off the native input, so mixed
      // advances to true — it is never reported back by the control itself.
      final reported = <bool?>[];
      final node = FocusNode();
      addTearDown(node.dispose);

      for (final start in <bool?>[false, true, null]) {
        await pump(
          tester,
          FluentCheckbox(
            key: key,
            checked: start,
            focusNode: node,
            onChanged: reported.add,
          ),
        );
        await tester.tap(find.byKey(key));
        await tester.pump();
      }
      expect(reported, <bool?>[true, false, true]);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(reported.length, 4, reason: 'keyboard activation must work');
    });

    testWidgets('null onChanged disables it for real', (tester) async {
      await pump(tester, const FluentCheckbox(key: key));
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeDisabled,
      );

      await hover(tester);
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeDisabled,
        reason: 'a disabled checkbox must not adopt the hover stroke',
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();
      expect(
        boxOf(tester).border!.top.color,
        light.colors.neutralStrokeDisabled,
      );
    });

    testWidgets('semantics announce the tri-state', (tester) async {
      for (final entry in <bool?, (bool, bool)>{
        false: (false, false),
        true: (true, false),
        null: (false, true),
      }.entries) {
        final (checked, mixed) = entry.value;
        await pump(
          tester,
          FluentCheckbox(
            key: key,
            checked: entry.key,
            semanticLabel: 'Agree',
            onChanged: (_) {},
          ),
        );
        expect(
          tester.getSemantics(find.byKey(key)),
          matchesSemantics(
            label: 'Agree',
            hasCheckedState: true,
            isChecked: checked,
            isCheckStateMixed: mixed,
            isEnabled: true,
            isFocusable: true,
            hasEnabledState: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
          reason: 'checked=${entry.key}',
        );
      }
    });

    testWidgets('a disabled checkbox still announces its state', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentCheckbox(key: key, checked: true, semanticLabel: 'Agree'),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Agree',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          // Not focusable, not activatable, and no tap action: a disabled
          // control must not advertise itself to assistive tech.
          // FluentInteractive
          // refuses focus while disabled. The tap ACTION survives, because the
          // shared primitive keeps its GestureDetector attached and no-ops
          // inside the handler; see the report accompanying this component.
          hasTapAction: false,
        ),
      );
    });
  });

  group('against the Figma fixture', () {
    final spec = loadSpec('checkbox');

    /// Maps a Figma variable path straight onto the core token it names.
    ///
    /// The point of the fixture's `tokens` map: nobody reverse-engineers
    /// `#FF0F6CBD` back into `compoundBrandBackground`, and a renamed Figma
    /// variable fails loudly here instead of drifting silently.
    Color tokenColor(FluentThemeData theme, String token) {
      final c = theme.colors;
      return switch (token) {
        'Neutral/Stroke/Accessible/Rest' => c.neutralStrokeAccessible,
        'Neutral/Stroke/Accessible/Hover' => c.neutralStrokeAccessibleHover,
        'Neutral/Stroke/Accessible/Pressed' => c.neutralStrokeAccessiblePressed,
        'Neutral/Stroke/Disabled/Rest' => c.neutralStrokeDisabled,
        'Brand/Stroke/Compound/Rest' => c.compoundBrandStroke,
        'Brand/Stroke/Compound/Hover' => c.compoundBrandStrokeHover,
        'Brand/Stroke/Compound/Pressed' => c.compoundBrandStrokePressed,
        'Brand/Background/Compound/Rest' => c.compoundBrandBackground,
        'Brand/Background/Compound/Hover' => c.compoundBrandBackgroundHover,
        'Brand/Background/Compound/Pressed' => c.compoundBrandBackgroundPressed,
        'Brand/Foreground/Compound/Rest' => c.compoundBrandForeground1,
        'Brand/Foreground/Compound/Hover' => c.compoundBrandForeground1Hover,
        'Brand/Foreground/Compound/Pressed' =>
          c.compoundBrandForeground1Pressed,
        'Neutral/Foreground/Inverted/1/Rest' => c.neutralForegroundInverted,
        'Neutral/Foreground/Inverted/1/Hover' =>
          c.neutralForegroundInvertedHover,
        'Neutral/Foreground/Inverted/1/Pressed' =>
          c.neutralForegroundInvertedPressed,
        'Neutral/Foreground/Disabled/Rest' => c.neutralForegroundDisabled,
        'Neutral/Foreground/1/Rest' => c.neutralForeground1,
        'Neutral/Foreground/2/Rest' => c.neutralForeground2,
        'Neutral/Foreground/3/Rest' => c.neutralForeground3,
        _ => fail('$token is not mapped onto a core token'),
      };
    }

    /// The indicator box: named `Background` when Figma draws it as a bare
    /// rectangle (unchecked, and the circular mixed state) and `Icon` when the
    /// box is an icon instance carrying the glyph (checked, standard mixed).
    SpecPart boxOfSpec(SpecVariant variant) => variant.parts.firstWhere(
      (p) => p.name == 'Background' || p.name == 'Icon',
    );

    /// The glyph inside the box, or null when the variant draws none.
    SpecPart? glyphOfSpec(SpecVariant variant) {
      for (final part in variant.parts) {
        if (part.name == 'Indeterminate shape' || part.name == 'Shape') {
          return part;
        }
      }
      return null;
    }

    test('the axes are Style x Status x State, and there is no Size axis', () {
      expect(spec.properties['Style'], <String>['Standard', 'Circular']);
      expect(spec.properties['Status'], <String>[
        'Unchecked',
        'Checked',
        'Indeterminate',
      ]);
      expect(spec.properties['State'], <String>[
        'Rest',
        'Hover',
        'Pressed',
        'Disabled',
        'Focus',
      ]);
      expect(spec.variants.length, 30);
      expect(
        spec.properties.containsKey('Size'),
        isFalse,
        reason:
            'FluentCheckboxSize.large is upstream-only — Figma draws one size',
      );
    });

    const shapes = <String, FluentCheckboxShape>{
      'Standard': FluentCheckboxShape.square,
      'Circular': FluentCheckboxShape.circular,
    };
    const statuses = <String, bool?>{
      'Unchecked': false,
      'Checked': true,
      'Indeterminate': null,
    };

    for (final shape in shapes.entries) {
      for (final status in statuses.entries) {
        for (final state in const <String>[
          'Rest',
          'Hover',
          'Pressed',
          'Disabled',
        ]) {
          final variant = spec.variant(<String, String>{
            'Style': shape.key,
            'Status': status.key,
            'State': state,
          });

          testWidgets(variant.name, (tester) async {
            final theme = FluentThemeData.light(
              fontPlatform: FluentFontPlatform.web,
            );
            final enabled = state != 'Disabled';
            await pump(
              tester,
              FluentCheckbox(
                key: key,
                checked: status.value,
                shape: shape.value,
                label: const Text('Label'),
                onChanged: enabled ? (_) {} : null,
              ),
              theme: theme,
            );

            TestGesture? mouse;
            if (state == 'Hover' || state == 'Pressed') {
              mouse = await hover(tester);
              if (state == 'Pressed') {
                await mouse.down(tester.getCenter(find.byKey(key)));
                await tester.pump();
              }
            }

            final box = boxOfSpec(variant);
            final decoration = boxOf(tester);

            expect(
              tester.getSize(find.byType(DecoratedBox).first),
              Size(box.size.width, box.size.height),
              reason: 'indicator box',
            );
            expect(
              tester.getSize(find.byKey(key)).height,
              variant.size.height,
              reason: 'root height',
            );

            // Figma pins the CIRCULAR mixed box at `Corner radius/X-Large` (8)
            // rather than Circular, which on a 16 box is the same full round.
            // Anything at or past half the box is a circle; below that the
            // radius is compared exactly.
            final radius = decoration.borderRadius!.resolve(TextDirection.ltr);
            final expectedRadius = box.radius!.topLeft.x;
            if (expectedRadius >= box.size.width / 2) {
              expect(
                radius.topLeft.x,
                greaterThanOrEqualTo(box.size.width / 2),
                reason: 'a fully rounded box',
              );
            } else {
              expect(radius, BorderRadius.circular(expectedRadius));
            }

            final strokeToken = box.tokens['strokes']?.first;
            final fillToken = box.tokens['fills']?.first;
            if (strokeToken != null) {
              expect(box.strokeWidth, FluentStroke.thin);
              expect(decoration.border!.top.width, FluentStroke.thin);
              expect(
                decoration.border!.top.color,
                tokenColor(theme, strokeToken),
                reason: 'box stroke',
              );
            } else {
              // Figma's checked box is a fill with no stroke at all. We keep a
              // thin border in the fill's own token so the box still has an
              // outline in high contrast; identical pixels either way.
              expect(box.strokeWidth, 0);
              expect(
                decoration.border!.top.color,
                decoration.color,
                reason: 'the extra border must be invisible',
              );
            }

            expect(
              decoration.color,
              fillToken == null
                  ? theme.colors.transparentBackground
                  : tokenColor(theme, fillToken),
              reason: 'box fill',
            );

            final glyph = glyphOfSpec(variant);
            if (glyph == null) {
              expect(glyphOf(tester).glyph, FluentCheckboxGlyph.none);
            } else {
              expect(glyphOf(tester).glyph, isNot(FluentCheckboxGlyph.none));
              expect(
                glyphOf(tester).color,
                tokenColor(theme, glyph.tokens['fills']!.first),
                reason: 'glyph tone',
              );
            }

            final text = variant.text!;
            final style = resolvedTextStyleOf(tester, of: find.byKey(key));
            expect(style.fontSize, text.fontSize);
            expect(style.height! * text.fontSize, text.lineHeight);
            expect(
              style.color,
              tokenColor(theme, text.tokens['fills']!.first),
              reason: 'label colour',
            );

            if (mouse != null && state == 'Pressed') {
              await mouse.up();
              await tester.pump();
            }
          });
        }
      }
    }

    testWidgets('the indicator and label sit where Figma puts them', (
      tester,
    ) async {
      // Style=Standard, Status=Unchecked, State=Rest: `Checkbox elements` is a
      // 32x32 frame padded 8 all round, then itemSpacing 4, then `Text wrapper
      // for offset` padded top 6 / right 8 / left 0.
      final variant = spec.variant(const <String, String>{
        'Style': 'Standard',
        'Status': 'Unchecked',
        'State': 'Rest',
      });
      final elements = variant.parts.firstWhere(
        (p) => p.name == 'Checkbox elements',
      );
      final wrapper = variant.parts.firstWhere(
        (p) => p.name == 'Text wrapper for offset',
      );

      await pump(
        tester,
        FluentCheckbox(key: key, label: const Text('Label'), onChanged: (_) {}),
      );

      final root = tester.getTopLeft(find.byKey(key));
      expect(
        tester.getTopLeft(find.byType(DecoratedBox).first) - root,
        Offset(elements.padding!.left, elements.padding!.top),
        reason: 'the indicator sits inside its own 8px margin box',
      );
      expect(
        tester.getTopLeft(find.text('Label')) - root,
        Offset(
          elements.size.width + variant.gap! + wrapper.padding!.left,
          wrapper.padding!.top,
        ),
        reason: 'itemSpacing 4 plus the wrapper inset, and the 6px nudge down',
      );
    });

    testWidgets('the focus ring takes Figma radius, on the whole control', (
      tester,
    ) async {
      // Every State=Focus variant strokes the root frame at `Corner
      // radius/Medium`, around the full 77x32 control rather than the box.
      final variant = spec.variant(const <String, String>{
        'Style': 'Standard',
        'Status': 'Unchecked',
        'State': 'Focus',
      });
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentCheckbox(
          key: key,
          label: const Text('Label'),
          focusNode: node,
          onChanged: (_) {},
        ),
      );

      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((c) => c.foregroundPainter)
          .whereType<FluentFocusRingPainter>()
          .first;
      expect(
        painter.borderRadius,
        BorderRadius.circular(variant.radius.topLeft.x),
      );
    });

    testWidgets('the glyphs are the shapes and sizes Figma draws', (
      tester,
    ) async {
      // The glyph is painted, not composed, so it is replayed onto a recording
      // canvas. Figma places all three inside the 16 indicator: the checkmark
      // 8x6 at (4,5), the mixed square 8x8 at (4,4) with a radius-2 corner, and
      // the mixed circle 8 across. The painter works in its own 12 glyph box,
      // which sits 2 in from the indicator on every side — hence the +2.
      const inset = 2.0;
      final standard = spec.variant(const <String, String>{
        'Style': 'Standard',
        'Status': 'Indeterminate',
        'State': 'Rest',
      });
      final circular = spec.variant(const <String, String>{
        'Style': 'Circular',
        'Status': 'Indeterminate',
        'State': 'Rest',
      });
      final checked = spec.variant(const <String, String>{
        'Style': 'Standard',
        'Status': 'Checked',
        'State': 'Rest',
      });
      final square = glyphOfSpec(standard)!;
      final dot = glyphOfSpec(circular)!;
      final tick = glyphOfSpec(checked)!;

      const glyphBox = Size.square(12);
      const black = Color(0xFF000000);

      final tickCanvas = _GlyphRecorder();
      const FluentCheckboxGlyphPainter(
        glyph: FluentCheckboxGlyph.checkmark,
        color: black,
      ).paint(tickCanvas, glyphBox);
      final bounds = tickCanvas.path!.getBounds().inflate(
        FluentStroke.width15 / 2,
      );
      expect(bounds.width, closeTo(tick.size.width, 0.01));
      expect(bounds.height, closeTo(tick.size.height, 0.01));
      expect(
        bounds.left + inset,
        closeTo(4, 0.01),
        reason: 'tick x in the box',
      );
      expect(bounds.top + inset, closeTo(5, 0.01), reason: 'tick y in the box');

      final squareCanvas = _GlyphRecorder();
      const FluentCheckboxGlyphPainter(
        glyph: FluentCheckboxGlyph.square,
        color: black,
      ).paint(squareCanvas, glyphBox);
      expect(squareCanvas.rrect!.width, square.size.width);
      expect(squareCanvas.rrect!.height, closeTo(square.size.height, 0.01));
      expect(squareCanvas.rrect!.left + inset, 4);
      expect(squareCanvas.rrect!.top + inset, 4);
      expect(
        squareCanvas.rrect!.tlRadiusX,
        FluentRadius.small.x,
        reason: 'Square12Filled rounds its corners by 2 — not a sharp square',
      );

      final dotCanvas = _GlyphRecorder();
      const FluentCheckboxGlyphPainter(
        glyph: FluentCheckboxGlyph.circle,
        color: black,
      ).paint(dotCanvas, glyphBox);
      expect(dotCanvas.radius! * 2, dot.size.width);
      expect(dotCanvas.center, glyphBox.center(Offset.zero));
    });
  });
}

/// Captures the one shape a [FluentCheckboxGlyphPainter] draws.
///
/// `implements Canvas` plus `noSuchMethod` rather than a real recording: the
/// painter draws exactly one primitive per glyph, and the point is to read its
/// numbers back, not to rasterise it.
class _GlyphRecorder implements Canvas {
  RRect? rrect;
  Path? path;
  Offset? center;
  double? radius;

  @override
  void drawRRect(RRect rrect, Paint paint) => this.rrect = rrect;

  @override
  void drawPath(Path path, Paint paint) => this.path = path;

  @override
  void drawCircle(Offset c, double r, Paint paint) {
    center = c;
    radius = r;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
