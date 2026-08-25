// Tristate is the tri-state semantics flag `dart:ui` defines; the semantics
// library imports it rather than re-exporting it.
import 'dart:ui' show Tristate;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSpinButton` is the wave's first component built on [EditableText]
/// rather than on Material, so these tests cover three things at once: pixel
/// fidelity against the two Figma sets, the one transition
/// `useSpinButtonStyles.styles.ts` declares, and the numeric contract —
/// clamping, precision and the keyboard bindings `useSpinButton.tsx` handles.
void main() {
  const key = Key('spin');
  const width = 280.0;

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
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
      home: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  Finder under(Type type) =>
      find.descendant(of: find.byKey(key), matching: find.byType(type));

  /// The control's own decorated surface. First in tree order — the stepper
  /// halves decorate themselves further down.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(under(DecoratedBox))
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// The resting rule, or null when the appearance draws none.
  ///
  /// Both rules are a [FluentInputUnderline] — the resting one directly, the
  /// brand one inside [FluentInputFocusUnderline] — so they are told apart by
  /// thickness rather than by order. The resting rule is the 1px one.
  FluentInputUnderline? restingRuleOf(WidgetTester tester) {
    final rules = tester
        .widgetList<FluentInputUnderline>(under(FluentInputUnderline))
        .where((r) => r.thickness == FluentStroke.thin);
    return rules.isEmpty ? null : rules.first;
  }

  /// The brand focus bar. Always in the tree: the style always resolves a
  /// colour for it, and upstream's `::after` is scaled to nothing rather than
  /// removed when the field is at rest.
  FluentInputFocusUnderline focusBarOf(WidgetTester tester) => tester
      .widget<FluentInputFocusUnderline>(under(FluentInputFocusUnderline));

  /// How far the focus bar has grown, 0 to 1 — the `scaleX` upstream animates.
  double focusProgressOf(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(
          of: under(FluentInputFocusUnderline),
          matching: find.byType(Transform),
        ),
      )
      .transform
      .entry(0, 0);

  FluentSpinButtonChevronPainter chevronOf(
    WidgetTester tester,
    FluentSpinButtonStepperDirection direction,
  ) => tester
      .widgetList<CustomPaint>(under(CustomPaint))
      .map((c) => c.painter)
      .whereType<FluentSpinButtonChevronPainter>()
      .firstWhere((p) => p.direction == direction);

  Finder stepper(FluentSpinButtonStepperDirection direction) =>
      find.byWidgetPredicate(
        (w) => w is FluentSpinButtonStepper && w.direction == direction,
      );

  Color? stepperFillOf(
    WidgetTester tester,
    FluentSpinButtonStepperDirection direction,
  ) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: stepper(direction),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first
      .color;

  /// Every [Padding] under the control, outermost first: the Contents inset,
  /// then the text slot's, then the two steppers'.
  List<EdgeInsets> paddingsOf(WidgetTester tester) => tester
      .widgetList<Padding>(under(Padding))
      .map((p) => p.padding.resolve(TextDirection.ltr))
      .toList();

  EditableText editableOf(WidgetTester tester) =>
      tester.widget<EditableText>(under(EditableText));

  TextEditingController controllerOf(WidgetTester tester) =>
      editableOf(tester).controller;

  /// Figma stores a fully transparent token as `#00FFFFFF` and core stores CSS
  /// `transparent`, which is `rgba(0,0,0,0)`. Both are invisible, so only the
  /// alpha is observable and only the alpha is asserted.
  void expectFill(Color? actual, Color? expected, String reason) {
    if (expected == null || expected.a == 0) {
      expect(actual?.a ?? 0, 0, reason: reason);
    } else {
      expect(actual?.toARGB32(), expected.toARGB32(), reason: reason);
    }
  }

  /// Focus travels on a microtask, so the rebuild it triggers lands on the
  /// frame *after* the one that applied it. Two pumps put the tree in its
  /// focused state with the underline animation at t = 0.
  Future<void> settleFocus(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  Widget build({
    double? value = 5,
    ValueChanged<double?>? onChanged = _noop,
    FluentSpinButtonAppearance appearance = FluentSpinButtonAppearance.outline,
    FluentSpinButtonSize size = FluentSpinButtonSize.medium,
    bool readOnly = false,
    bool invalid = false,
    double? min,
    double? max,
    double step = 1,
    double pageStep = 1,
    int? precision,
    String? placeholder,
    String? displayValue,
    String? semanticLabel,
    FocusNode? focusNode,
    FluentSpinButtonStyle? style,
  }) => FluentSpinButton(
    key: key,
    value: value,
    onChanged: onChanged,
    appearance: appearance,
    size: size,
    readOnly: readOnly,
    invalid: invalid,
    min: min,
    max: max,
    step: step,
    pageStep: pageStep,
    precision: precision,
    placeholder: placeholder,
    displayValue: displayValue,
    semanticLabel: semanticLabel,
    focusNode: focusNode,
    style: style,
  );

  /// A host that echoes the reported value back, the way a real caller does.
  /// Without it every assertion about a *second* step would be testing an
  /// uncontrolled widget, where `value` never moves.
  Widget controlled({
    required List<double?> reported,
    double? initial = 5,
    double? min,
    double? max,
    double step = 1,
    double pageStep = 1,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    var value = initial;
    return StatefulBuilder(
      builder: (context, setState) => FluentSpinButton(
        key: key,
        value: value,
        min: min,
        max: max,
        step: step,
        pageStep: pageStep,
        readOnly: readOnly,
        focusNode: focusNode,
        onChanged: (next) {
          reported.add(next);
          setState(() => value = next);
        },
      ),
    );
  }

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('spin_button');
    final steppers = loadSpec('spin_button_stepper');

    SpecVariant v(String style, String state, [String size = 'Medium']) =>
        spec.variant({'Style': style, 'State': state, 'Size': size});

    const names = <FluentSpinButtonAppearance, String>{
      FluentSpinButtonAppearance.outline: 'Outline',
      FluentSpinButtonAppearance.filledDarker: 'Filled darker',
      FluentSpinButtonAppearance.filledLighter: 'Filled lighter',
      FluentSpinButtonAppearance.underline: 'Underline',
    };

    test('the fixtures cover both component sets whole', () {
      expect(spec.variants.length, 56);
      expect(steppers.variants.length, 8);
      expect(spec.properties['State'], <String>[
        'Rest',
        'Hover',
        'Pressed',
        'Selected',
        'Error',
        'Disabled',
        'Read only',
      ]);
    });

    testWidgets('geometry matches every size', (tester) async {
      for (final size in FluentSpinButtonSize.values) {
        final label = size == FluentSpinButtonSize.medium ? 'Medium' : 'Small';
        final variant = v('Outline', 'Rest', label);
        final contents = variant.part('Contents');
        final slot = variant.part('Text');
        final glyph = variant.part('Placeholder text');
        final increase = variant.part('Increase stepper');
        final decrease = variant.part('Decrease stepper');

        await pump(tester, build(size: size));
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(key)).height,
          contents.size.height,
          reason: '$label: height',
        );
        expect(
          decorationOf(tester).borderRadius?.resolve(TextDirection.ltr),
          contents.radius,
          reason: '$label: radius',
        );

        final paddings = paddingsOf(tester);
        expect(
          paddings[0],
          EdgeInsets.only(left: contents.padding!.left),
          reason: '$label: Contents inset',
        );
        expect(paddings[1], slot.padding, reason: '$label: text slot inset');

        final style = editableOf(tester).style;
        expect(
          style.fontSize,
          glyph.text!.fontSize,
          reason: '$label: fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          glyph.text!.lineHeight,
          reason: '$label: lineHeight',
        );

        for (final (direction, part)
            in <(FluentSpinButtonStepperDirection, SpecPart)>[
              (FluentSpinButtonStepperDirection.increase, increase),
              (FluentSpinButtonStepperDirection.decrease, decrease),
            ]) {
          expect(
            tester.getSize(stepper(direction)),
            part.size,
            reason: '$label: ${direction.name} stepper size',
          );
          expect(
            paddings[direction == FluentSpinButtonStepperDirection.increase
                ? 2
                : 3],
            part.padding,
            reason: '$label: ${direction.name} stepper inset',
          );
        }

        // The two halves stack to exactly the control's height, which is what
        // makes the column flush rather than centred with slack either side.
        expect(
          increase.size.height + decrease.size.height,
          contents.size.height,
          reason: '$label: stepper column height',
        );
      }
    });

    testWidgets('resting fill matches every appearance', (tester) async {
      for (final entry in names.entries) {
        final variant = v(entry.value, 'Rest');
        await pump(tester, build(appearance: entry.key));
        await tester.pumpAndSettle();
        expectFill(
          decorationOf(tester).color,
          variant.part('Contents').fill,
          '${entry.value}: resting fill',
        );
      }
    });

    testWidgets('outline strokes its box; underline strokes nothing', (
      tester,
    ) async {
      await pump(tester, build());
      await tester.pumpAndSettle();
      final outline = v('Outline', 'Rest').part('Contents');
      expect(decorationOf(tester).border!.top.color, outline.stroke);
      expect(decorationOf(tester).border!.top.width, outline.strokeWidth);

      await pump(
        tester,
        build(appearance: FluentSpinButtonAppearance.underline),
      );
      await tester.pumpAndSettle();
      expect(v('Underline', 'Rest').part('Contents').strokeWidth, 0);
      expect(decorationOf(tester).border, isNull);
    });

    testWidgets('the filled appearances keep a transparent border', (
      tester,
    ) async {
      // A deliberate divergence, recorded in the report: Figma paints no stroke
      // at all, React declares `colorTransparentStrokeInteractive`. The two are
      // the same pixels in light and dark; in high contrast the token turns
      // opaque and becomes the only outline a filled input has.
      for (final appearance in <FluentSpinButtonAppearance>[
        FluentSpinButtonAppearance.filledDarker,
        FluentSpinButtonAppearance.filledLighter,
      ]) {
        expect(
          v(names[appearance]!, 'Rest').part('Contents').strokeWidth,
          0,
          reason: '${appearance.name}: Figma paints no stroke',
        );
        await pump(tester, build(appearance: appearance));
        await tester.pumpAndSettle();
        final border = decorationOf(tester).border;
        expect(border, isNotNull, reason: '${appearance.name}: border present');
        expect(border!.top.color.a, 0, reason: '${appearance.name}: invisible');
        expect(border.top.width, FluentStroke.thin);
      }
    });

    testWidgets('the bottom rule walks the accessible ramp', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      for (final appearance in <FluentSpinButtonAppearance>[
        FluentSpinButtonAppearance.outline,
        FluentSpinButtonAppearance.underline,
      ]) {
        await pump(tester, build(appearance: appearance), theme: theme);
        await tester.pumpAndSettle();

        final rest = v(names[appearance]!, 'Rest');
        expect(restingRuleOf(tester)!.thickness, FluentStroke.thin);
        expect(
          restingRuleOf(tester)?.color.toARGB32(),
          rest.part('Thin underline').fill!.toARGB32(),
          reason: '${appearance.name}: resting rule',
        );

        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expect(
          restingRuleOf(tester)?.color.toARGB32(),
          v(
            names[appearance]!,
            'Hover',
          ).part('Thin underline').fill!.toARGB32(),
          reason: '${appearance.name}: hover rule',
        );

        await mouse.down(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expect(
          restingRuleOf(tester)?.color.toARGB32(),
          v(
            names[appearance]!,
            'Pressed',
          ).part('Thin underline').fill!.toARGB32(),
          reason: '${appearance.name}: pressed rule',
        );
        await mouse.up();
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the filled appearances draw no bottom rule', (tester) async {
      for (final appearance in <FluentSpinButtonAppearance>[
        FluentSpinButtonAppearance.filledDarker,
        FluentSpinButtonAppearance.filledLighter,
      ]) {
        expect(
          v(
            names[appearance]!,
            'Rest',
          ).parts.where((p) => p.name == 'Thin underline'),
          isEmpty,
          reason: '${appearance.name}: Figma draws no rule',
        );
        await pump(tester, build(appearance: appearance));
        await tester.pumpAndSettle();
        expect(restingRuleOf(tester), isNull);
      }
    });

    testWidgets('the focus underline is a 2px brand rule from the centre', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final selected = v('Underline', 'Selected');
      final full = selected.part('Thin underline');
      final half = v(
        'Underline',
        'Pressed',
      ).parts.lastWhere((p) => p.name == 'Thin underline');

      expect(full.size, const Size(width, FluentStroke.thick));
      // Figma froze one frame of the scaleX animation on every Pressed
      // variant: half the control's width, centred. That is the transform
      // origin, and it is the only place the design file states it.
      expect(half.size, const Size(width / 2, FluentStroke.thick));

      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        build(
          appearance: FluentSpinButtonAppearance.underline,
          focusNode: node,
        ),
        theme: theme,
      );
      await tester.pumpAndSettle();
      expect(focusProgressOf(tester), 0);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      final bar = focusBarOf(tester);
      expect(bar.thickness, FluentStroke.thick);
      expect(focusProgressOf(tester), 1);
      expect(bar.color.toARGB32(), full.fill!.toARGB32());
      expect(
        theme.colors.neutralStrokeAccessibleSelected.toARGB32(),
        full.fill!.toARGB32(),
        reason: 'Figma binds Neutral/Stroke/Accessible/Selected',
      );

      // Both rules sit ON the control's bottom edge and span it, so the box the
      // scale animates is the full-width one Figma draws.
      final field = tester.getRect(find.byKey(key));
      final barRect = tester.getRect(under(FluentInputFocusUnderline));
      expect(barRect.width, width);
      expect(barRect.height, FluentStroke.thick);
      expect(barRect.bottom, field.bottom);

      final ruleRect = tester.getRect(under(FluentInputUnderline).first);
      expect(ruleRect.width, width);
      expect(ruleRect.height, FluentStroke.thin);
      expect(ruleRect.bottom, field.bottom);

      // And the frame Figma froze: half the width, centred. `Transform.scale`
      // has its origin at the centre, which is CSS's default 50% origin, so a
      // full-width bar at scaleX 0.5 paints exactly that rect.
      expect(
        tester
            .widget<Transform>(
              find.descendant(
                of: under(FluentInputFocusUnderline),
                matching: find.byType(Transform),
              ),
            )
            .alignment,
        Alignment.center,
      );
      expect(barRect.width / 2, half.size.width);
    });

    testWidgets('error paints the danger token', (tester) async {
      for (final entry in names.entries) {
        final variant = v(entry.value, 'Error');
        await pump(tester, build(appearance: entry.key, invalid: true));
        await tester.pumpAndSettle();

        if (entry.key == FluentSpinButtonAppearance.underline) {
          expect(
            restingRuleOf(tester)?.color.toARGB32(),
            variant.part('Thin underline').fill!.toARGB32(),
            reason: '${entry.value}: error rule',
          );
        } else {
          expect(
            decorationOf(tester).border!.top.color.toARGB32(),
            variant.part('Contents').stroke!.toARGB32(),
            reason: '${entry.value}: error border',
          );
        }
      }
    });

    test('focus drops the error border back to the resting ramp', () {
      // `useSpinButtonStyles.styles.ts` scopes `colorPaletteRedBorder2` to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // spin button is drawn like any other focused one and the brand rule is
      // what marks it. Figma cannot disagree: Error and Selected are two values
      // of a single `State` axis, so no variant is both.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final style = resolveFluentSpinButtonStyle(
        resolveFluentSpinButtonState(
          field: const SizedBox.shrink(),
          invalid: true,
          focused: true,
        ),
        theme,
      );

      expect(
        style.borderColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralStroke1,
        reason: 'focused invalid border falls back to Neutral/Stroke/1/Rest',
      );
      expect(
        style.bottomRuleColor!.resolve(const <WidgetState>{}),
        theme.colors.neutralStrokeAccessible,
        reason: 'and the resting rule comes back with it',
      );
    });

    testWidgets('disabled and read only share a surface, not a text colour', (
      tester,
    ) async {
      final disabled = v('Outline', 'Disabled');
      final readOnly = v('Outline', 'Read only');

      // Figma states the equality this test is built on.
      expect(
        disabled.part('Contents').stroke,
        readOnly.part('Contents').stroke,
      );
      expect(disabled.part('Contents').fill, isNull);
      expect(readOnly.part('Contents').fill, isNull);
      expect(
        disabled.part('Placeholder text').fill,
        isNot(readOnly.part('Placeholder text').fill),
      );

      await pump(tester, build(onChanged: null));
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color?.a ?? 0, 0);
      expect(
        decorationOf(tester).border!.top.color.toARGB32(),
        disabled.part('Contents').stroke!.toARGB32(),
      );
      expect(
        editableOf(tester).style.color?.toARGB32(),
        disabled.part('Placeholder text').fill!.toARGB32(),
      );

      await pump(tester, build(readOnly: true));
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color?.a ?? 0, 0);
      expect(
        decorationOf(tester).border!.top.color.toARGB32(),
        readOnly.part('Contents').stroke!.toARGB32(),
      );
      expect(
        editableOf(tester).style.color?.toARGB32(),
        readOnly.part('Placeholder text').fill!.toARGB32(),
      );
    });

    testWidgets('the placeholder takes its own token, not a faded value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, build(value: null, placeholder: 'qty'), theme: theme);
      await tester.pumpAndSettle();

      final placeholder = tester.widget<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      );
      expect(
        placeholder.style!.color!.toARGB32(),
        v('Outline', 'Rest').part('Placeholder text').fill!.toARGB32(),
      );
      expect(placeholder.style!.color, theme.colors.neutralForeground4);
      expect(editableOf(tester).style.color, theme.colors.neutralForeground1);
    });

    testWidgets('the stepper column matches its own component set', (
      tester,
    ) async {
      SpecVariant s(String style, String state) =>
          steppers.variant({'Style': style, 'State': state});

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      for (final (appearance, style) in <(FluentSpinButtonAppearance, String)>[
        (FluentSpinButtonAppearance.outline, 'Default'),
        (FluentSpinButtonAppearance.filledDarker, 'Darker'),
      ]) {
        await pump(tester, build(appearance: appearance));
        await tester.pumpAndSettle();

        const up = FluentSpinButtonStepperDirection.increase;
        const down = FluentSpinButtonStepperDirection.decrease;

        expectFill(
          stepperFillOf(tester, up),
          s(style, 'Rest').fill,
          '$style rest',
        );
        expect(
          chevronOf(tester, up).color.toARGB32(),
          s(style, 'Rest').part('Shape').fill!.toARGB32(),
          reason: '$style: resting chevron',
        );

        await mouse.moveTo(tester.getCenter(stepper(up)));
        await tester.pumpAndSettle();

        expectFill(
          stepperFillOf(tester, up),
          s(style, 'Hover').fill,
          '$style: hovered stepper fill',
        );
        expect(
          chevronOf(tester, up).color.toARGB32(),
          s(style, 'Hover').part('Shape').fill!.toARGB32(),
          reason: '$style: hovered chevron',
        );
        // Hovering one half must leave the other alone.
        expectFill(
          stepperFillOf(tester, down),
          s(style, 'Rest').fill,
          '$style: the other half holds at rest',
        );

        await mouse.down(tester.getCenter(stepper(up)));
        await tester.pumpAndSettle();
        expectFill(
          stepperFillOf(tester, up),
          s(style, 'Pressed').fill,
          '$style: pressed stepper fill',
        );
        await mouse.up();
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }

      // Read only pins the DISABLED stepper in Figma, not the rest one.
      for (final inert in <(String, Widget)>[
        ('disabled', build(onChanged: null)),
        ('read only', build(readOnly: true)),
      ]) {
        await pump(tester, inert.$2);
        await tester.pumpAndSettle();
        expect(
          chevronOf(
            tester,
            FluentSpinButtonStepperDirection.increase,
          ).color.toARGB32(),
          s('Default', 'Disabled').part('Shape').fill!.toARGB32(),
          reason: 'inert chevron: ${inert.$1}',
        );
      }
    });

    testWidgets('the chevron keeps the 8 x 4.5 ink of a 12 glyph', (
      tester,
    ) async {
      final shape = steppers
          .variant({'Style': 'Default', 'State': 'Rest'})
          .part('Shape');
      await pump(tester, build());
      await tester.pumpAndSettle();

      final painter = chevronOf(
        tester,
        FluentSpinButtonStepperDirection.increase,
      );
      expect(painter.glyphSize, FluentSize.size120);
      expect(painter.glyphSize * 8 / 12, shape.size.width);
      expect(painter.glyphSize * 4.5 / 12, shape.size.height);
    });
  });

  group('motion', () {
    // useSpinButtonStyles.styles.ts declares exactly one transition: `transform`
    // on the ::after focus underline. Enter is durationNormal (200ms) on
    // curveDecelerateMid; exit is durationUltraFast (50ms) on curveAccelerateMid.
    testWidgets('the focus underline grows over 200ms', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, build(focusNode: node));
      await tester.pumpAndSettle();
      expect(focusProgressOf(tester), 0);

      node.requestFocus();
      await settleFocus(tester);
      await tester.pump(const Duration(milliseconds: 100));
      final midway = focusProgressOf(tester);
      expect(midway, greaterThan(0));
      expect(midway, lessThan(1), reason: 'must be mid-tween, not instant');

      await tester.pump(const Duration(milliseconds: 100));
      expect(focusProgressOf(tester), 1);
    });

    testWidgets('the focus underline retracts over 50ms', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, build(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(focusProgressOf(tester), 1);

      node.unfocus();
      await settleFocus(tester);
      await tester.pump(const Duration(milliseconds: 25));
      expect(focusProgressOf(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 25));
      expect(focusProgressOf(tester), 0);
    });

    testWidgets('reduced motion lands the underline on the first frame', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, build(focusNode: node), reducedMotion: true);
      await tester.pumpAndSettle();

      node.requestFocus();
      await settleFocus(tester);
      expect(focusProgressOf(tester), 1);
    });

    testWidgets('nothing else animates', (tester) async {
      // The surface, the border and the bottom rule change on the frame the
      // pointer arrives — upstream transitions `transform` and nothing else.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, build(), theme: theme);
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(
        decorationOf(tester).border!.top.color,
        theme.colors.neutralStroke1Hover,
      );
      expect(
        restingRuleOf(tester)?.color,
        theme.colors.neutralStrokeAccessibleHover,
      );
    });
  });

  group('theming', () {
    testWidgets('a subtree FluentThemeOverride reaches the component', (
      tester,
    ) async {
      const magenta = Color(0xFFFF00FF);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const <FluentColorToken, Color>{
              FluentColorToken.neutralStroke1: magenta,
            },
            child: Center(
              child: SizedBox(width: width, child: build()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).border!.top.color, magenta);
    });

    testWidgets('FluentSpinButtonTheme sits under the widget style', (
      tester,
    ) async {
      const fromTheme = Color(0xFF112233);
      const fromWidget = Color(0xFF445566);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentSpinButtonTheme(
            style: FluentSpinButtonStyle.from(
              backgroundColor: fromTheme,
              bottomRuleColor: fromTheme,
            ),
            child: Center(
              child: SizedBox(
                width: width,
                child: build(
                  style: FluentSpinButtonStyle.from(
                    backgroundColor: fromWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The widget's own style wins where the two overlap; the subtree theme
      // still supplies what the widget left alone.
      expect(decorationOf(tester).color, fromWidget);
      expect(restingRuleOf(tester)?.color, fromTheme);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in FluentSpinButtonAppearance.values) {
        await pump(tester, build(appearance: appearance), theme: theme);
        await tester.pumpAndSettle();

        final border = decorationOf(tester).border;
        final rule = restingRuleOf(tester)?.color;
        final visible =
            (border != null && border.top.color.a == 1) ||
            (rule != null && rule.a == 1);
        expect(
          visible,
          isTrue,
          reason: '${appearance.name}: nothing outlines the control',
        );
      }
    });

    testWidgets('the focus underline stays opaque in high contrast', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, build(focusNode: node), theme: theme);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(focusBarOf(tester).color.a, 1);
    });
  });

  group('value', () {
    testWidgets('steppers report a clamped, rounded value', (tester) async {
      final reported = <double?>[];
      await pump(
        tester,
        controlled(
          reported: reported,
          initial: 9.5,
          min: 0,
          max: 10,
          step: 0.5,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(stepper(FluentSpinButtonStepperDirection.increase));
      await tester.pumpAndSettle();
      expect(reported, <double?>[10]);

      await tester.tap(stepper(FluentSpinButtonStepperDirection.increase));
      await tester.pumpAndSettle();
      // Already at the ceiling: clamping means no second report.
      expect(reported, <double?>[10]);

      await tester.tap(stepper(FluentSpinButtonStepperDirection.decrease));
      await tester.pumpAndSettle();
      expect(reported.last, 9.5);
    });

    testWidgets('precision follows the step unless it is given', (
      tester,
    ) async {
      await pump(tester, build(value: 1, step: 0.25));
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '1.00');

      await pump(tester, build(value: 1, step: 0.25, precision: 0));
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '1');

      await pump(tester, build(value: 1, step: 1));
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '1');
    });

    testWidgets('displayValue replaces the formatted number', (tester) async {
      await pump(tester, build(value: 50, displayValue: '50%'));
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '50%');
    });

    testWidgets('committing text clamps, rounds and reports', (tester) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        controlled(reported: reported, min: 0, max: 10, focusNode: node),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      controllerOf(tester).text = '42';
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported, <double?>[10]);
      expect(controllerOf(tester).text, '10');
    });

    testWidgets('unparseable text is discarded on commit', (tester) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, controlled(reported: reported, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      controllerOf(tester).text = 'twelve';
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported, isEmpty);
      expect(controllerOf(tester).text, '5');
    });

    testWidgets('an empty field commits null', (tester) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, controlled(reported: reported, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      controllerOf(tester).clear();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported, <double?>[null]);
    });

    testWidgets('losing focus commits', (tester) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, controlled(reported: reported, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      controllerOf(tester).text = '7';
      await tester.pump();
      node.unfocus();
      await tester.pumpAndSettle();
      expect(reported, <double?>[7]);
    });
  });

  group('keyboard', () {
    Future<(List<double?>, FocusNode)> focused(
      WidgetTester tester, {
      double? value = 5,
      double? min,
      double? max,
      double step = 1,
      double pageStep = 1,
    }) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        controlled(
          reported: reported,
          initial: value,
          min: min,
          max: max,
          step: step,
          pageStep: pageStep,
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      return (reported, node);
    }

    testWidgets('Up and Down move by one step', (tester) async {
      final (reported, _) = await focused(tester, step: 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(reported.last, 7);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(reported.last, 5);
    });

    testWidgets('PageUp and PageDown move by one page step', (tester) async {
      final (reported, _) = await focused(tester, pageStep: 10);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(reported.last, 15);
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(reported.last, 5);
    });

    testWidgets('Home and End jump to the bounds when there are any', (
      tester,
    ) async {
      final (bounded, _) = await focused(tester, min: 1, max: 9);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(bounded.last, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(bounded.last, 9);

      // Unbounded: upstream checks `min !== undefined` before handling the key,
      // so an open-ended spin button ignores both.
      final (open, _) = await focused(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(open, isEmpty);
    });

    testWidgets('Escape puts back the committed value', (tester) async {
      final (reported, _) = await focused(tester);
      controllerOf(tester).text = '99';
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '5');
      expect(reported, isEmpty);
    });
  });

  group('disabled and read only are real states', () {
    testWidgets('disabled refuses focus, hover and every callback', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentSpinButton(key: key, value: 5, focusNode: node),
        theme: theme,
      );
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse);
      expect(focusProgressOf(tester), 0);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        decorationOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
        reason: 'hover must not reach a disabled control',
      );

      await tester.tap(
        stepper(FluentSpinButtonStepperDirection.increase),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(controllerOf(tester).text, '5');
    });

    testWidgets('read only keeps focus and refuses change', (tester) async {
      final reported = <double?>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        controlled(reported: reported, readOnly: true, focusNode: node),
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(node.hasFocus, isTrue);
      expect(focusProgressOf(tester), 1);
      expect(editableOf(tester).readOnly, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.tap(
        stepper(FluentSpinButtonStepperDirection.increase),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(reported, isEmpty);
    });
  });

  group('semantics', () {
    testWidgets('announces the value, the label and both directions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        build(value: 5, min: 0, max: 10, step: 2, semanticLabel: 'Quantity'),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byKey(key));
      expect(node.label, 'Quantity');
      expect(node.value, '5');
      expect(node.increasedValue, '7');
      expect(node.decreasedValue, '3');
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isTrue,
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease),
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('the step preview is clamped like the value is', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, build(value: 10, min: 0, max: 10));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byKey(key)).increasedValue, '10');
      handle.dispose();
    });

    testWidgets('displayValue is what gets announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, build(value: 50, displayValue: '50 percent'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byKey(key)).value, '50 percent');
      handle.dispose();
    });

    testWidgets('read only and disabled are announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, build(readOnly: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(key))
            .getSemanticsData()
            .flagsCollection
            .isReadOnly,
        isTrue,
      );

      await pump(tester, build(onChanged: null));
      await tester.pumpAndSettle();
      final data = tester.getSemantics(find.byKey(key)).getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      handle.dispose();
    });

    testWidgets('the steppers do not announce themselves twice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, build(semanticLabel: 'Quantity'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  // One shape, one implementation: both bottom rules are the `input.dart`
  // primitives, which is where the `max(thickness, radius)` + clip trick that
  // keeps a 4px corner on a 1px rule lives.
  //
  // Upstream rounds them. `useSpinButtonStyles.styles.ts` gives the root
  // `::after` — the focus rule — `borderBottomLeftRadius`/`Right` of
  // `borderRadiusMedium` plus `clipPath: inset(calc(100% - 2px) 0 0 0)`, and
  // the `::before` that carries the resting bottom edge `borderRadius:
  // borderRadiusMedium`. Only the `underline` appearance squares them off
  // again: `'::after': { borderRadius: tokens.borderRadiusNone }`, commented
  // "remove rounded corners from focus underline".
  testWidgets('both bottom rules follow the field corner radius', (
    tester,
  ) async {
    final bottomsOfMedium = BorderRadius.only(
      bottomLeft: FluentRadius.allMedium.bottomLeft,
      bottomRight: FluentRadius.allMedium.bottomRight,
    );
    for (final entry in <FluentSpinButtonAppearance, BorderRadius>{
      FluentSpinButtonAppearance.outline: bottomsOfMedium,
      FluentSpinButtonAppearance.underline: BorderRadius.zero,
    }.entries) {
      await pump(tester, build(appearance: entry.key));
      await tester.pumpAndSettle();

      final bar = focusBarOf(tester);
      expect(bar.thickness, FluentStroke.thick);
      expect(
        bar.borderRadius,
        entry.value,
        reason: '${entry.key.name}: the focus rule',
      );
      expect(
        restingRuleOf(tester)!.borderRadius,
        entry.value,
        reason: '${entry.key.name}: the resting rule',
      );
    }
  });

  group('style struct', () {
    test('merge is per-property and copyWith keeps the rest', () {
      const a = Color(0xFF000001);
      const b = Color(0xFF000002);
      final base = FluentSpinButtonStyle.from(
        backgroundColor: a,
        glyphSize: 12,
      );
      final merged = base.merge(FluentSpinButtonStyle.from(backgroundColor: b));

      expect(merged.backgroundColor!.resolve(const <WidgetState>{}), b);
      expect(merged.glyphSize!.resolve(const <WidgetState>{}), 12);
      expect(base.merge(null), base);

      final copied = base.copyWith(
        glyphSize: const WidgetStatePropertyAll<double?>(16),
      );
      expect(copied.backgroundColor!.resolve(const <WidgetState>{}), a);
      expect(copied.glyphSize!.resolve(const <WidgetState>{}), 16);
      expect(
        base,
        FluentSpinButtonStyle.from(backgroundColor: a, glyphSize: 12),
      );
      expect(
        base.hashCode,
        FluentSpinButtonStyle.from(backgroundColor: a, glyphSize: 12).hashCode,
      );
    });
  });
}

void _noop(double? _) {}
