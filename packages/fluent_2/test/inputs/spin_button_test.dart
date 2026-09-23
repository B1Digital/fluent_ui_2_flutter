// Tristate is the tri-state semantics flag `dart:ui` defines; the semantics
// library imports it rather than re-exporting it.
import 'dart:ui' as ui show ImageByteFormat;
import 'dart:ui' show Tristate;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSpinButton` is built on [EditableText] rather than on Material, so
/// these tests cover three things at once: pixel fidelity against upstream's
/// SpinButton as it renders in Chrome, the one transition
/// `useSpinButtonStyles.styles.ts` declares, and the numeric contract —
/// clamping, precision and the keyboard bindings `useSpinButton.tsx` handles.
void main() {
  const key = Key('spin');
  const boundary = Key('boundary');
  const width = _width;

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

  /// The border, read as the tones the painter was handed.
  FluentInputBorderPainter borderOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(under(CustomPaint))
      .map((p) => p.foregroundPainter)
      .whereType<FluentInputBorderPainter>()
      .single;

  /// The control rasterised at [_ratio] device pixels per logical one — the
  /// ratio the upstream capture was taken at. Needs a [RepaintBoundary] keyed
  /// [boundary] round the control.
  Future<ByteData> pixelsOf(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
            .toImage(pixelRatio: _ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;

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

  Finder chevronFinder(FluentSpinButtonStepperDirection direction) =>
      find.descendant(
        of: stepper(direction),
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint && w.painter is FluentSpinButtonChevronPainter,
        ),
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

  // The oracle is upstream's `useSpinButtonStyles.styles.ts` as it renders in
  // Chrome on the live storybook. The Figma fixtures supply the numbers where
  // the two agree; where they do not, the upstream value is asserted directly
  // and the Figma one is noted beside it.
  group('pixel fidelity against upstream', () {
    final spec = loadSpec('spin_button');
    final steppers = loadSpec('spin_button_stepper');
    final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final c = light.colors;

    SpecVariant v(String style, String state, [String size = 'Medium']) =>
        spec.variant({'Style': style, 'State': state, 'Size': size});

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
      // Measured in Chrome from the border box: the `<input>` starts at the
      // root's `padding-left` (10, or 8 on small, where Figma has 6 + 2) and
      // stops 4 short of the 24px stepper column — the grid's
      // `columnGap: spacingHorizontalXS`. Figma insets the text slot by 2 on
      // both sides instead.
      const textInset = <FluentSpinButtonSize, double>{
        FluentSpinButtonSize.medium: FluentSpacing.mNudge,
        FluentSpinButtonSize.small: FluentSpacing.s,
      };
      // Each chevron's 14px box, from the column's start edge and the control's
      // top: upstream's svg rect, which Chrome paints at a whole-pixel top, plus
      // the 1px its 16 viewBox is centred by at 14 wide.
      const glyphs = <FluentSpinButtonSize, (Offset, Offset)>{
        FluentSpinButtonSize.medium: (Offset(5, 3), Offset(5, 16)),
        FluentSpinButtonSize.small: (Offset(4, 1), Offset(4, 10)),
      };
      for (final size in FluentSpinButtonSize.values) {
        final label = size == FluentSpinButtonSize.medium ? 'Medium' : 'Small';
        final variant = v('Outline', 'Rest', label);
        final glyph = variant.part('Placeholder text');

        await pump(tester, build(size: size));
        await tester.pumpAndSettle();

        final field = tester.getRect(find.byKey(key));
        expect(
          field.height,
          variant.part('Contents').size.height,
          reason: '$label: height',
        );
        expect(
          decorationOf(tester).borderRadius,
          FluentRadius.allMedium,
          reason: '$label: radius',
        );

        final text = tester.getRect(under(EditableText));
        expect(text.left - field.left, textInset[size], reason: '$label: text');
        expect(
          field.right - text.right,
          24 + FluentSpacing.xs,
          reason: '$label: the gap before the stepper column',
        );

        final editable = editableOf(tester);
        expect(
          editable.cursorWidth,
          FluentStroke.thin,
          reason: "$label: the browser's caret is 1px",
        );
        expect(
          editable.style.fontSize,
          glyph.text!.fontSize,
          reason: '$label: fontSize',
        );
        expect(
          editable.style.height! * editable.style.fontSize!,
          glyph.text!.lineHeight,
          reason: '$label: lineHeight',
        );

        final column = field.right - 24;
        for (final (direction, part, box)
            in <(FluentSpinButtonStepperDirection, SpecPart, Offset)>[
              (
                FluentSpinButtonStepperDirection.increase,
                variant.part('Increase stepper'),
                glyphs[size]!.$1,
              ),
              (
                FluentSpinButtonStepperDirection.decrease,
                variant.part('Decrease stepper'),
                glyphs[size]!.$2,
              ),
            ]) {
          final half = tester.getRect(stepper(direction));
          expect(half.size, part.size, reason: '$label: ${direction.name}');
          expect(half.left, column, reason: '$label: flush with the end');
          expect(
            tester.getRect(chevronFinder(direction)),
            Offset(column, field.top) + box & const Size.square(14),
            reason: '$label: ${direction.name} chevron box',
          );
        }
      }
    });

    testWidgets("the chevron is upstream's 16px icon drawn at 14", (
      tester,
    ) async {
      // The ink Chrome paints for `ChevronUp16Regular` /
      // `ChevronDown16Regular`, in CSS px from the stepper column's start and
      // the control's top, read off the capture at DPR 4 (any pixel at least
      // 2% covered), and its ink area: ~1px arms, where the stroked chevron
      // this replaced covered half as much again.
      const ink = <FluentSpinButtonSize, (Rect, Rect)>{
        FluentSpinButtonSize.medium: (
          Rect.fromLTRB(7.5, 7.25, 16.5, 12.25),
          Rect.fromLTRB(7.5, 20.75, 16.5, 25.75),
        ),
        FluentSpinButtonSize.small: (
          Rect.fromLTRB(6.5, 5.25, 15.5, 10.25),
          Rect.fromLTRB(6.5, 14.75, 15.5, 19.75),
        ),
      };
      for (final size in FluentSpinButtonSize.values) {
        await pump(
          tester,
          RepaintBoundary(
            key: boundary,
            child: build(size: size),
          ),
          theme: light,
        );
        await tester.pumpAndSettle();
        final pixels = await pixelsOf(tester);
        final h = size == FluentSpinButtonSize.medium ? 32.0 : 24.0;
        for (final (half, want) in <(String, Rect)>[
          ('up', ink[size]!.$1),
          ('down', ink[size]!.$2),
        ]) {
          final (box, area) = inkOf(
            pixels,
            // Inside the ring, one half of the column.
            Rect.fromLTRB(
              width - 22,
              half == 'up' ? 2 : h / 2,
              width - 2,
              half == 'up' ? h / 2 : h - 2,
            ),
            ink: c.neutralForeground3,
          );
          final at = box.shift(const Offset(24 - width, 0));
          for (final (edge, got, expected) in <(String, double, double)>[
            ('left', at.left, want.left),
            ('top', at.top, want.top),
            ('right', at.right, want.right),
            ('bottom', at.bottom, want.bottom),
          ]) {
            expect(
              got,
              closeTo(expected, .25),
              reason: '${size.name} $half: ink $edge',
            );
          }
          expect(area, closeTo(9.8, .6), reason: '${size.name} $half: weight');
        }
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      // (fill, sides, bottom). Underline keeps the root's
      // `colorNeutralBackground1` — Figma paints it no fill — and the filled
      // two carry `colorTransparentStroke` round all four sides, where Figma
      // draws no stroke at all.
      final expected = <FluentSpinButtonAppearance, (Color, Color?, Color?)>{
        FluentSpinButtonAppearance.outline: (
          c.neutralBackground1,
          c.neutralStroke1,
          c.neutralStrokeAccessible,
        ),
        FluentSpinButtonAppearance.underline: (
          c.neutralBackground1,
          null,
          c.neutralStrokeAccessible,
        ),
        FluentSpinButtonAppearance.filledDarker: (
          c.neutralBackground3,
          c.transparentStroke,
          null,
        ),
        FluentSpinButtonAppearance.filledLighter: (
          c.neutralBackground1,
          c.transparentStroke,
          null,
        ),
      };
      // Where Figma and upstream agree, the fixture says so.
      expect(
        v('Outline', 'Rest').part('Contents').stroke?.toARGB32(),
        c.neutralStroke1.toARGB32(),
      );
      expect(
        v('Outline', 'Rest').part('Thin underline').fill?.toARGB32(),
        c.neutralStrokeAccessible.toARGB32(),
      );

      for (final entry in expected.entries) {
        final (fill, sides, bottom) = entry.value;
        await pump(tester, build(appearance: entry.key), theme: light);
        await tester.pumpAndSettle();
        final name = entry.key.name;
        expect(decorationOf(tester).color, fill, reason: '$name: fill');
        final border = borderOf(tester);
        expect(border.borderColor, sides, reason: '$name: sides');
        expect(border.bottomBorderColor, bottom, reason: '$name: bottom');
        expect(
          border.bottomBorderWidth,
          FluentStroke.thin,
          reason: '$name: a 1px bottom',
        );
        if (sides != null) {
          expect(border.borderWidth, FluentStroke.thin, reason: '$name: 1px');
        }
      }
    });

    testWidgets('underline squares its border and focus bar, not its fill', (
      tester,
    ) async {
      // `underline` zeroes `::before`'s radius ("corners look strange if
      // rounded") and `underlineInteractive` the `::after`'s; the root keeps
      // `borderRadiusMedium`, which is what rounds its fill and the steppers'.
      await pump(
        tester,
        build(appearance: FluentSpinButtonAppearance.underline),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).borderRadius, FluentRadius.allMedium);
      expect(borderOf(tester).radius, BorderRadius.zero);
      expect(focusBarOf(tester).borderRadius, BorderRadius.zero);

      await pump(tester, build());
      await tester.pumpAndSettle();
      expect(borderOf(tester).radius, FluentRadius.allMedium);
      expect(
        focusBarOf(tester).borderRadius,
        BorderRadius.only(
          bottomLeft: FluentRadius.allMedium.bottomLeft,
          bottomRight: FluentRadius.allMedium.bottomRight,
        ),
      );
    });

    testWidgets('the focus underline is a 2px brand rule from the centre', (
      tester,
    ) async {
      // `colorCompoundBrandStroke`; Figma binds
      // `Neutral/Stroke/Accessible/Selected`, the same value in every theme.
      final full = v('Underline', 'Selected').part('Thin underline');
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
        theme: light,
      );
      await tester.pumpAndSettle();
      expect(focusProgressOf(tester), 0);

      node.requestFocus();
      await tester.pumpAndSettle();
      final bar = focusBarOf(tester);
      expect(bar.thickness, FluentStroke.thick);
      expect(focusProgressOf(tester), 1);
      expect(bar.color, c.compoundBrandStroke);
      expect(bar.color.toARGB32(), full.fill!.toARGB32());

      // The bar sits ON the control's bottom edge and spans it, so the box the
      // scale animates is the full-width one.
      final field = tester.getRect(find.byKey(key));
      final barRect = tester.getRect(under(FluentInputFocusUnderline));
      expect(barRect.width, width);
      expect(barRect.height, FluentStroke.thick);
      expect(barRect.bottom, field.bottom);
      // `Transform.scale` has its origin at the centre, CSS's default 50%, so
      // a full-width bar at scaleX 0.5 paints the frame Figma froze.
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

    testWidgets('the bottom colour meets the sides on the CSS corner diagonal', (
      tester,
    ) async {
      // A browser splits two border colours along the line from the border
      // box's corner to the padding box's: here (0, h) → (1, h − 1), 45°. The
      // darker bottom colour therefore climbs half-way round each bottom arc.
      // At DPR 4, device pixel (7, 4h − 6) covers CSS x 1.75–2, 1.25–1.5 above
      // the bottom: inside the ring, below the diagonal and above the bottom
      // 1px, where the old 1px strip over a uniform border left the side
      // colour. (4, 4h − 8) is the same arc above the diagonal.
      await pump(
        tester,
        RepaintBoundary(key: boundary, child: build()),
        theme: light,
      );
      await tester.pumpAndSettle();
      final pixels = await pixelsOf(tester);
      final bottom = (32 * _ratio).round();
      expectPixel(
        pixels,
        7,
        bottom - 6,
        c.neutralStrokeAccessible,
        'below the diagonal: the bottom colour',
      );
      expectPixel(
        pixels,
        4,
        bottom - 8,
        c.neutralStroke1,
        'above the diagonal: the side colour',
      );
    });

    testWidgets('the border paints over a hovered stepper', (tester) async {
      // Upstream draws the border on `::before` at `z-index: 10`, above the
      // stepper buttons, and rounds the increment's `borderTopRightRadius`.
      // So a hovered stepper keeps the ring along its top and end, and its
      // fill stops at the field's rounded corner.
      await pump(
        tester,
        RepaintBoundary(key: boundary, child: build()),
        theme: light,
      );
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(
        tester.getCenter(stepper(FluentSpinButtonStepperDirection.increase)),
      );
      await tester.pumpAndSettle();
      expect(
        stepperFillOf(tester, FluentSpinButtonStepperDirection.increase),
        c.subtleBackgroundHover,
      );

      final pixels = await pixelsOf(tester);
      final right = (width * _ratio).round();
      expectPixel(
        pixels,
        right - 12 * _ratio.round(),
        1,
        c.neutralStroke1Hover,
        'the top side, over the stepper',
      );
      expectPixel(
        pixels,
        right - 2,
        16 * _ratio.round() ~/ 2,
        c.neutralStroke1Hover,
        'the end side, over the stepper',
      );
      expect(
        pixels.getUint8(((right - 1) * 4) + 3),
        0,
        reason: 'the fill follows the corner: nothing outside the arc',
      );
    });

    testWidgets('hover and press walk the outline ramps', (tester) async {
      for (final appearance in <FluentSpinButtonAppearance>[
        FluentSpinButtonAppearance.outline,
        FluentSpinButtonAppearance.underline,
      ]) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          build(appearance: appearance, focusNode: node),
          theme: light,
        );
        await tester.pumpAndSettle();
        final name = appearance.name;
        final outline = appearance == FluentSpinButtonAppearance.outline;

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expect(
          borderOf(tester).bottomBorderColor,
          c.neutralStrokeAccessibleHover,
          reason: '$name: hover bottom',
        );
        if (outline) {
          expect(borderOf(tester).borderColor, c.neutralStroke1Hover);
        }

        // Pressing the text focuses it on the way down, as a browser does.
        await mouse.down(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expect(node.hasFocus, isTrue, reason: '$name: focused on mousedown');
        expect(
          borderOf(tester).bottomBorderColor,
          c.neutralStrokeAccessiblePressed,
          reason: '$name: pressed bottom',
        );
        expect(
          focusBarOf(tester).color,
          c.compoundBrandStrokePressed,
          reason: '$name: `:focus-within:active::after`',
        );
        if (outline) {
          expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
        }
        await mouse.up();
        await mouse.removePointer();
        node.unfocus();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('focus holds the Pressed stop, hovered or not', (tester) async {
      // `outlineInteractive` and `underlineInteractive` write
      // `:active,:focus-within` as one rule, which Griffel sorts after
      // `:hover`: a focused field keeps the Pressed colours under the mouse.
      for (final appearance in <FluentSpinButtonAppearance>[
        FluentSpinButtonAppearance.outline,
        FluentSpinButtonAppearance.underline,
      ]) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          build(appearance: appearance, focusNode: node),
          theme: light,
        );
        node.requestFocus();
        await tester.pumpAndSettle();
        final outline = appearance == FluentSpinButtonAppearance.outline;

        void expectPressedStop(String when) {
          expect(
            borderOf(tester).bottomBorderColor,
            c.neutralStrokeAccessiblePressed,
            reason: '${appearance.name} $when: bottom',
          );
          if (outline) {
            expect(
              borderOf(tester).borderColor,
              c.neutralStroke1Pressed,
              reason: '${appearance.name} $when: sides',
            );
          }
        }

        expectPressedStop('focused');
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expectPressedStop('focused and hovered');
        await mouse.removePointer();
        node.unfocus();
        await tester.pumpAndSettle();
      }
    });

    test('the filled border lifts to the interactive stroke', () {
      // `filled` rests on `colorTransparentStroke`; `filledInteractive` moves
      // `:hover,:focus-within` — and so `:active` — to the Interactive token.
      // The two differ only in high contrast.
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final hc = theme.colors;
      expect(hc.transparentStroke, isNot(hc.transparentStrokeInteractive));
      WidgetStateProperty<Color?> border({bool focused = false}) =>
          resolveFluentSpinButtonStyle(
            resolveFluentSpinButtonState(
              field: const SizedBox.shrink(),
              focused: focused,
              appearance: FluentSpinButtonAppearance.filledDarker,
            ),
            theme,
          ).borderColor!;

      expect(border().resolve(const <WidgetState>{}), hc.transparentStroke);
      expect(
        border().resolve(const <WidgetState>{WidgetState.hovered}),
        hc.transparentStrokeInteractive,
      );
      expect(
        border().resolve(const <WidgetState>{WidgetState.pressed}),
        hc.transparentStrokeInteractive,
      );
      expect(
        border(focused: true).resolve(const <WidgetState>{}),
        hc.transparentStrokeInteractive,
      );
    });

    testWidgets('error strokes every side in colorPaletteRedBorder2', (
      tester,
    ) async {
      // `#d13438` in light. Figma binds the status token (`#c50f1f`); the
      // palette layer knows nothing of high contrast, where upstream's own
      // token resolves to the status colour, so the port uses that there.
      final red = c.palette.stroke2Rest(FluentPaletteFamily.red)!;
      expect(red, const Color(0xFFD13438));
      expect(
        v('Outline', 'Error').part('Contents').stroke?.toARGB32(),
        c.statusDangerBorder2.toARGB32(),
        reason: 'the Figma value this overrides',
      );
      for (final appearance in FluentSpinButtonAppearance.values) {
        await pump(
          tester,
          build(appearance: appearance, invalid: true),
          theme: light,
        );
        await tester.pumpAndSettle();
        final border = borderOf(tester);
        final underline = appearance == FluentSpinButtonAppearance.underline;
        expect(
          border.borderColor,
          underline ? null : red,
          reason: '${appearance.name}: sides',
        );
        expect(
          border.bottomBorderColor ?? border.borderColor,
          red,
          reason: '${appearance.name}: bottom',
        );
      }

      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final style = resolveFluentSpinButtonStyle(
        resolveFluentSpinButtonState(
          field: const SizedBox.shrink(),
          invalid: true,
        ),
        hc,
      );
      expect(
        style.borderColor!.resolve(const <WidgetState>{}),
        hc.colors.statusDangerBorder2,
      );
    });

    test('a focused invalid spin button takes the focused ramp', () {
      // `useSpinButtonStyles.styles.ts` scopes `colorPaletteRedBorder2` to
      // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
      // spin button is drawn like any other focused one and the brand bar is
      // what marks it.
      final style = resolveFluentSpinButtonStyle(
        resolveFluentSpinButtonState(
          field: const SizedBox.shrink(),
          invalid: true,
          focused: true,
        ),
        light,
      );
      expect(
        style.borderColor!.resolve(const <WidgetState>{}),
        c.neutralStroke1Pressed,
      );
      expect(
        style.bottomRuleColor!.resolve(const <WidgetState>{}),
        c.neutralStrokeAccessiblePressed,
      );
    });

    testWidgets('disabled clears the fill and greys every side', (
      tester,
    ) async {
      final disabled = v('Outline', 'Disabled');
      for (final appearance in FluentSpinButtonAppearance.values) {
        await pump(
          tester,
          build(appearance: appearance, onChanged: null),
          theme: light,
        );
        await tester.pumpAndSettle();
        final name = appearance.name;
        expect(decorationOf(tester).color?.a, 0, reason: '$name: no fill');
        final border = borderOf(tester);
        expect(
          border.bottomBorderColor ?? border.borderColor,
          c.neutralStrokeDisabled,
          reason: '$name: bottom',
        );
        if (appearance != FluentSpinButtonAppearance.underline) {
          expect(border.borderColor, c.neutralStrokeDisabled, reason: name);
        }
        expect(
          editableOf(tester).style.color?.toARGB32(),
          disabled.part('Placeholder text').fill!.toARGB32(),
          reason: '$name: text',
        );
      }
    });

    testWidgets(
      'read only looks exactly like rest; only its steppers go inert',
      (tester) async {
        // Upstream has no read-only rule on the root: it passes `readOnly` to
        // the `<input>` and renders both steppers `disabled`. Figma greys the
        // whole surface like Disabled; upstream wins.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);

        for (final appearance in FluentSpinButtonAppearance.values) {
          await pump(tester, build(appearance: appearance), theme: light);
          await tester.pumpAndSettle();
          final restFill = decorationOf(tester).color;
          final restBorder = borderOf(tester);

          await pump(
            tester,
            build(appearance: appearance, readOnly: true),
            theme: light,
          );
          await tester.pumpAndSettle();
          final name = appearance.name;
          expect(decorationOf(tester).color, restFill, reason: '$name: fill');
          final border = borderOf(tester);
          expect(border.borderColor, restBorder.borderColor, reason: name);
          expect(
            border.bottomBorderColor,
            restBorder.bottomBorderColor,
            reason: '$name: bottom',
          );
          expect(
            editableOf(tester).style.color,
            c.neutralForeground1,
            reason: '$name: the value keeps full contrast',
          );

          await mouse.moveTo(
            tester.getCenter(
              stepper(FluentSpinButtonStepperDirection.increase),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            chevronOf(tester, FluentSpinButtonStepperDirection.increase).color,
            c.neutralForegroundDisabled,
            reason: '$name: the stepper is disabled',
          );
          expect(
            stepperFillOf(tester, FluentSpinButtonStepperDirection.increase)?.a,
            0,
            reason: '$name: and takes no hover',
          );
          if (appearance == FluentSpinButtonAppearance.outline) {
            expect(
              borderOf(tester).borderColor,
              c.neutralStroke1Hover,
              reason: 'the root still takes :hover',
            );
          }
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('the placeholder takes its own token, not a faded value', (
      tester,
    ) async {
      await pump(tester, build(value: null, placeholder: 'qty'), theme: light);
      await tester.pumpAndSettle();

      final placeholder = tester.widget<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      );
      expect(
        placeholder.style!.color!.toARGB32(),
        v('Outline', 'Rest').part('Placeholder text').fill!.toARGB32(),
      );
      expect(placeholder.style!.color, c.neutralForeground4);
      expect(editableOf(tester).style.color, c.neutralForeground1);
    });

    testWidgets('the stepper column matches its own component set', (
      tester,
    ) async {
      // Figma's `.Spin button stepper` set agrees with upstream in light:
      // `colorSubtleBackgroundHover` and `neutralBackground1Hover` are the
      // same grey there.
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

      // Read only pins the DISABLED stepper, as upstream's `disabled` buttons.
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

    test('stepper fills follow the appearance, in dark as well', () {
      // Upstream's buttons: `colorSubtleBackground*` on outline and underline,
      // the ramp of the field's own fill on the filled two. Subtle and
      // `neutralBackground1` only coincide in light.
      final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      final d = dark.colors;
      expect(d.subtleBackgroundHover, isNot(d.neutralBackground1Hover));
      for (final (appearance, hover, pressed)
          in <(FluentSpinButtonAppearance, Color, Color)>[
            (
              FluentSpinButtonAppearance.outline,
              d.subtleBackgroundHover,
              d.subtleBackgroundPressed,
            ),
            (
              FluentSpinButtonAppearance.underline,
              d.subtleBackgroundHover,
              d.subtleBackgroundPressed,
            ),
            (
              FluentSpinButtonAppearance.filledLighter,
              d.neutralBackground1Hover,
              d.neutralBackground1Pressed,
            ),
            (
              FluentSpinButtonAppearance.filledDarker,
              d.neutralBackground3Hover,
              d.neutralBackground3Pressed,
            ),
          ]) {
        final fill = resolveFluentSpinButtonStyle(
          resolveFluentSpinButtonState(
            field: const SizedBox.shrink(),
            appearance: appearance,
          ),
          dark,
        ).stepperBackgroundColor!;
        expect(
          fill.resolve(const <WidgetState>{WidgetState.hovered}),
          hover,
          reason: '${appearance.name}: hover',
        );
        expect(
          fill.resolve(const <WidgetState>{WidgetState.pressed}),
          pressed,
          reason: '${appearance.name}: pressed',
        );
      }
    });

    testWidgets('pressing a stepper with a mouse focuses the field', (
      tester,
    ) async {
      // Upstream's stepper is a `<button tabindex=-1>`: mousedown focuses it,
      // the root turns `:focus-within`, and the bar grows while it is held.
      // The port focuses the field instead, which draws the same and keeps
      // the arrow keys working.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, build(focusNode: node), theme: light);
      await tester.pumpAndSettle();

      final at = tester.getCenter(
        stepper(FluentSpinButtonStepperDirection.increase),
      );
      final mouse = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(focusProgressOf(tester), 1);
      expect(focusBarOf(tester).color, c.compoundBrandStrokePressed);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'focus stays in the control');
      expect(focusBarOf(tester).color, c.compoundBrandStroke);

      // A finger may be starting a scroll: no focus, no keyboard.
      node.unfocus();
      await tester.pumpAndSettle();
      final finger = await tester.startGesture(at);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse, reason: 'touch');
      await finger.up();
      await tester.pumpAndSettle();

      // Read-only steppers are upstream's `disabled` buttons: Chrome focuses
      // nothing on the press or the release.
      await pump(tester, build(focusNode: node, readOnly: true), theme: light);
      await tester.pumpAndSettle();
      final held = await tester.startGesture(at, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse, reason: 'read only');
      await held.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isFalse, reason: 'read only, released');

      // The read-only `<input>` itself still focuses on mousedown.
      final text = await tester.startGesture(
        tester.getRect(find.byKey(key)).centerLeft + const Offset(40, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(node.hasFocus, isTrue, reason: 'read only field, held');
      await text.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'read only field, released');
    });

    testWidgets(
      'a mouse press focuses without selecting the value',
      variant: TargetPlatformVariant.desktop(),
      (tester) async {
        // A browser selects nothing on a click. `EditableText` selects the
        // whole value on desktop when focus comes from outside it, so the
        // press has to go through the field's own `requestKeyboard`. At the
        // bound a step rewrites nothing, and a selection made on the press
        // would outlive the release.
        final rect = find.byKey(key);
        final up = stepper(FluentSpinButtonStepperDirection.increase);
        for (final (name, readOnly, at) in <(String, bool, Offset Function())>[
          ('text', false, () => tester.getCenter(rect)),
          ('read-only text', true, () => tester.getCenter(rect)),
          ('stepper at the bound', false, () => tester.getCenter(up)),
          (
            'padding',
            false,
            () => tester.getRect(rect).centerLeft + const Offset(4, 0),
          ),
        ]) {
          await pump(tester, build(value: 20, max: 20, readOnly: readOnly));
          await tester.pumpAndSettle();
          final press = await tester.startGesture(
            at(),
            kind: PointerDeviceKind.mouse,
          );
          await settleFocus(tester);
          expect(editableOf(tester).focusNode.hasFocus, isTrue, reason: name);
          expect(
            controllerOf(tester).selection.isCollapsed,
            isTrue,
            reason: '$name: held',
          );
          await press.up();
          await tester.pumpAndSettle();
          expect(
            controllerOf(tester).selection.isCollapsed,
            isTrue,
            reason: '$name: released',
          );
          // A fresh, unfocused field for the next case.
          await pump(tester, const SizedBox());
        }
      },
    );

    testWidgets('the mouse cursor follows upstream', (tester) async {
      // Chrome: the root's padding is `auto` (the arrow), the `<input>` is
      // `text`, an enabled stepper `pointer`, and a disabled root, input or
      // stepper — read-only steppers included — `not-allowed`.
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      Future<MouseCursor?> cursorAt(Offset at) async {
        await mouse.moveTo(at);
        await tester.pump();
        return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
      }

      Future<void> expectCursors(
        String name, {
        required MouseCursor padding,
        required MouseCursor text,
        required MouseCursor up,
      }) async {
        final field = tester.getRect(find.byKey(key));
        expect(
          await cursorAt(field.centerLeft + const Offset(4, 0)),
          padding,
          reason: '$name: padding',
        );
        expect(
          await cursorAt(field.centerLeft + const Offset(40, 12)),
          text,
          reason: '$name: text column, below the line box',
        );
        expect(
          await cursorAt(
            tester.getCenter(
              stepper(FluentSpinButtonStepperDirection.increase),
            ),
          ),
          up,
          reason: '$name: stepper',
        );
        await mouse.moveTo(Offset.zero);
        await tester.pump();
      }

      await pump(tester, build());
      await tester.pumpAndSettle();
      await expectCursors(
        'enabled',
        padding: SystemMouseCursors.basic,
        text: SystemMouseCursors.text,
        up: SystemMouseCursors.click,
      );

      await pump(tester, build(readOnly: true));
      await tester.pumpAndSettle();
      await expectCursors(
        'read only',
        padding: SystemMouseCursors.basic,
        text: SystemMouseCursors.text,
        up: SystemMouseCursors.forbidden,
      );

      await pump(tester, build(onChanged: null));
      await tester.pumpAndSettle();
      await expectCursors(
        'disabled',
        padding: SystemMouseCursors.forbidden,
        text: SystemMouseCursors.forbidden,
        up: SystemMouseCursors.forbidden,
      );
    });
  });

  group('motion', () {
    // useSpinButtonStyles.styles.ts declares exactly one transition: `transform`
    // on the ::after focus underline. Enter is durationNormal (200ms), exit is
    // durationUltraFast (50ms), both on CSS `ease` — the curve tokens sit in
    // `transitionDelay`, which the browser drops.
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

      expect(borderOf(tester).borderColor, theme.colors.neutralStroke1Hover);
      expect(
        borderOf(tester).bottomBorderColor,
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
      expect(borderOf(tester).borderColor, magenta);
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
      expect(borderOf(tester).bottomBorderColor, fromTheme);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in FluentSpinButtonAppearance.values) {
        await pump(tester, build(appearance: appearance), theme: theme);
        await tester.pumpAndSettle();

        final border = borderOf(tester);
        final visible = <Color?>[
          if (border.borderWidth > 0) border.borderColor,
          if (border.bottomBorderWidth > 0) border.bottomBorderColor,
        ].any((c) => c != null && c.a == 1);
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
        borderOf(tester).borderColor,
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

/// Every test lays the control out this wide.
const double _width = 280;

/// Device pixels per logical pixel in the pixel tests: upstream's capture DPR.
const double _ratio = 4;

/// Asserts the RGB of device pixel ([x], [y]) in a [_width]-wide capture.
void expectPixel(ByteData pixels, int x, int y, Color expected, String why) {
  final i = (y * (_width * _ratio).round() + x) * 4;
  final actual = [for (var c = 0; c < 3; c++) pixels.getUint8(i + c)];
  final want = [
    for (final channel in [expected.r, expected.g, expected.b])
      (channel * 255).round(),
  ];
  for (var c = 0; c < 3; c++) {
    expect(actual[c], closeTo(want[c], 3), reason: '$why: $actual vs $want');
  }
}

/// The bounding box, in logical pixels, of every pixel inside [within] that is
/// at least 2% [ink] over white, and the ink's area.
(Rect, double) inkOf(ByteData pixels, Rect within, {required Color ink}) {
  final stride = (_width * _ratio).round();
  final depth = 255 - (ink.r * 255).round();
  var (left, top, right, bottom, area) = (1e9, 1e9, -1e9, -1e9, 0.0);
  for (var y = (within.top * _ratio).round(); y < within.bottom * _ratio; y++) {
    for (
      var x = (within.left * _ratio).round();
      x < within.right * _ratio;
      x++
    ) {
      final cover = (255 - pixels.getUint8((y * stride + x) * 4)) / depth;
      if (cover <= .02) continue;
      area += cover.clamp(0, 1);
      left = left < x ? left : x.toDouble();
      top = top < y ? top : y.toDouble();
      right = right > x + 1 ? right : x + 1.0;
      bottom = bottom > y + 1 ? bottom : y + 1.0;
    }
  }
  return (
    Rect.fromLTRB(left / _ratio, top / _ratio, right / _ratio, bottom / _ratio),
    area / (_ratio * _ratio),
  );
}
