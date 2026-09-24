import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSearchBox` is the wave's first text input: it owns the `EditableText`
/// wiring the other input components will reuse. These tests therefore cover
/// the editor's behaviour as well as the look of its chrome — upstream's
/// SearchBox as it renders in Chrome on the live storybook, read off the Figma
/// `SearchBox` set wherever Figma agrees with it.
void main() {
  const key = Key('search-box');
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  final appearanceNames = <FluentSearchBoxAppearance, String>{
    FluentSearchBoxAppearance.filledDarker: 'Filled darker',
    FluentSearchBoxAppearance.filledLighter: 'Filled lighter',
    FluentSearchBoxAppearance.outline: 'Outline',
    FluentSearchBoxAppearance.transparent: 'Transparent',
  };
  final sizeNames = <FluentSearchBoxSize, String>{
    FluentSearchBoxSize.small: 'Small',
    FluentSearchBoxSize.medium: 'Medium',
    FluentSearchBoxSize.large: 'Large',
  };

  Future<void> pump(
    WidgetTester tester,
    Widget searchBox, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    double width = 468,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      // 468 is upstream's maxWidth. A search box fills the width it is given.
      home: Center(
        child: SizedBox(width: width, child: searchBox),
      ),
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

  /// The search box's own surface: the first box in the tree, under which the
  /// border, the content and the focus bar all sit.
  BoxDecoration surfaceOf(WidgetTester tester) => decorationsOf(tester).first;

  /// The border, shared with `FluentInput`.
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

  /// The bottom side's colour: its own, or the side colour running round.
  Color? bottomOf(WidgetTester tester) {
    final border = borderOf(tester);
    return border.bottomBorderColor ?? border.borderColor;
  }

  /// The 2px focus underline.
  BoxDecoration underlineOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// How far the focus underline has scaled: 0 hidden, 1 fully across.
  double underlineScaleOf(WidgetTester tester) => tester
      .widget<Transform>(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
      )
      .transform
      .storage[0];

  Finder glyph(FluentSearchBoxGlyph which) => find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.painter is FluentSearchBoxGlyphPainter &&
        (w.painter! as FluentSearchBoxGlyphPainter).glyph == which,
  );

  Future<TestGesture> mouseAt(WidgetTester tester, Offset location) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: location);
    addTearDown(mouse.removePointer);
    await tester.pump();
    return mouse;
  }

  Widget box({
    FluentSearchBoxAppearance appearance = FluentSearchBoxAppearance.outline,
    FluentSearchBoxSize size = FluentSearchBoxSize.medium,
    bool enabled = true,
    bool error = false,
    bool readOnly = false,
    TextEditingController? controller,
    FocusNode? focusNode,
    FluentSearchBoxStyle? style,
    String? placeholder = 'Search',
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
  }) => FluentSearchBox(
    key: key,
    appearance: appearance,
    size: size,
    enabled: enabled,
    error: error,
    readOnly: readOnly,
    controller: controller,
    focusNode: focusNode,
    style: style,
    placeholder: placeholder,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    onClear: onClear,
  );

  group('upstream fidelity', () {
    final spec = loadSpec('search_box');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 36);
      expect(spec.properties['Style'], appearanceNames.values.toList());
      expect(spec.properties['Size'], <String>['Small', 'Medium', 'Large']);
      expect(spec.properties['State'], <String>['Rest', 'Focus', 'Hover']);
    });

    testWidgets('height and type ramp match every size', (tester) async {
      for (final entry in sizeNames.entries) {
        // Figma and upstream agree here: 24 / 32 / 40, caption1 / body1 /
        // body2.
        final variant = spec.variant({
          'Style': 'Outline',
          'Size': entry.value,
          'State': 'Rest',
        });
        await pump(tester, box(size: entry.key));

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${entry.value}: height',
        );
        expect(
          surfaceOf(tester).borderRadius,
          FluentRadius.allMedium,
          reason: '${entry.value}: radius',
        );

        final text = tester
            .widget<RichText>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!;
        expect(
          text.fontSize,
          variant.text!.fontSize,
          reason: '${entry.value}: fontSize',
        );
        expect(
          text.height! * text.fontSize!,
          variant.text!.lineHeight,
          reason: '${entry.value}: lineHeight',
        );
      }
    });

    testWidgets('the content sits inside the border, on upstream pixels', (
      tester,
    ) async {
      // Measured in Chrome on components-searchbox--default, 200 wide, rects
      // relative to the border box. The border takes space as a CSS border
      // does; Transparent has only the bottom one, so its content box is 1px
      // shorter and 1px further left. Layout keeps the half pixel; paint snaps
      // the glyphs as Chrome does.
      const cases =
          <(FluentSearchBoxAppearance, FluentSearchBoxSize), List<double>>{
            // icon x, icon y, edge, text x, dismiss x, focused text right
            (FluentSearchBoxAppearance.outline, FluentSearchBoxSize.small): [
              7.0, 4.0, 16.0, 29.0, 177.0, 165.0, //
            ],
            (FluentSearchBoxAppearance.outline, FluentSearchBoxSize.medium): [
              9.0, 6.0, 20.0, 35.0, 171.0, 159.0, //
            ],
            (FluentSearchBoxAppearance.outline, FluentSearchBoxSize.large): [
              11.0, 8.0, 24.0, 41.0, 165.0, 153.0, //
            ],
            (
              FluentSearchBoxAppearance.transparent,
              FluentSearchBoxSize.small,
            ): [
              6.0, 3.5, 16.0, 28.0, 178.0, 166.0, //
            ],
            (
              FluentSearchBoxAppearance.transparent,
              FluentSearchBoxSize.medium,
            ): [
              8.0, 5.5, 20.0, 34.0, 172.0, 160.0, //
            ],
            (
              FluentSearchBoxAppearance.transparent,
              FluentSearchBoxSize.large,
            ): [
              10.0, 7.5, 24.0, 40.0, 166.0, 154.0, //
            ],
          };
      for (final MapEntry(key: (appearance, size), value: want)
          in cases.entries) {
        final label = '${appearance.name} ${size.name}';
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          box(appearance: appearance, size: size, focusNode: node),
          width: 200,
        );
        final origin = tester.getTopLeft(find.byKey(key));
        Rect rel(Finder f) => tester.getRect(f).shift(-origin);

        final icon = rel(glyph(FluentSearchBoxGlyph.search));
        expect(icon.left, want[0], reason: '$label: icon x');
        expect(icon.top, want[1], reason: '$label: icon y');
        expect(icon.width, want[2], reason: '$label: icon size');
        expect(
          rel(find.byType(EditableText)).left,
          want[3],
          reason: '$label: text x',
        );
        expect(
          rel(find.byType(EditableText)).right,
          // The trailing padding mirrors the leading one.
          200 - want[0],
          reason: '$label: unfocused text right edge',
        );

        node.requestFocus();
        await tester.pumpAndSettle();
        final dismiss = rel(glyph(FluentSearchBoxGlyph.dismiss));
        expect(dismiss.left, want[4], reason: '$label: dismiss x');
        expect(dismiss.top, want[1], reason: '$label: dismiss y');
        expect(dismiss.width, want[2], reason: '$label: dismiss size');
        expect(
          rel(find.byType(EditableText)).right,
          want[5],
          reason: '$label: focused text right edge',
        );
      }
    });

    testWidgets('no icon keeps the input padding, and RTL mirrors', (
      tester,
    ) async {
      // Chrome, outline medium, 200 wide: `contentBefore: null` leaves the
      // <input>'s padding-left (6) after the root's (8), so the text starts at
      // 15. Under `dir: rtl` every padding swaps sides.
      const cases = <(TextDirection, bool), (double, double)>{
        (TextDirection.ltr, false): (15, 191),
        (TextDirection.rtl, true): (9, 165),
        (TextDirection.rtl, false): (9, 185),
      };
      for (final MapEntry(key: (dir, icon), value: (left, right))
          in cases.entries) {
        await pump(
          tester,
          Directionality(
            textDirection: dir,
            child: FluentSearchBox(
              key: key,
              icon: icon ? null : const SizedBox.shrink(),
            ),
          ),
          width: 200,
        );
        final origin = tester.getTopLeft(find.byKey(key));
        final text = tester.getRect(find.byType(EditableText)).shift(-origin);
        expect(text.left, left, reason: '$dir icon $icon: text left');
        expect(text.right, right, reason: '$dir icon $icon: text right');
        if (icon) {
          final at = tester.getRect(glyph(FluentSearchBoxGlyph.search));
          expect(at.left - origin.dx, 171, reason: 'RTL icon x');
        }
      }
    });

    testWidgets('resting fill and border match every appearance', (
      tester,
    ) async {
      final c = light.colors;
      for (final entry in appearanceNames.entries) {
        await pump(tester, box(appearance: entry.key));
        await tester.pumpAndSettle();
        final name = entry.value;
        final border = borderOf(tester);

        switch (entry.key) {
          case FluentSearchBoxAppearance.outline:
            expect(surfaceOf(tester).color, c.neutralBackground1);
            expect(border.borderColor, c.neutralStroke1, reason: name);
            expect(border.bottomBorderColor, c.neutralStrokeAccessible);
          case FluentSearchBoxAppearance.filledLighter:
          case FluentSearchBoxAppearance.filledDarker:
            expect(
              surfaceOf(tester).color,
              entry.key == FluentSearchBoxAppearance.filledDarker
                  ? c.neutralBackground3
                  : c.neutralBackground1,
              reason: '$name fill',
            );
            // A real transparent-token border: invisible here, 1px of layout,
            // and opaque in high contrast.
            expect(border.borderColor, c.transparentStroke, reason: name);
            expect(border.borderColor!.a, 0, reason: name);
            expect(border.bottomBorderColor, isNull, reason: name);
          case FluentSearchBoxAppearance.transparent:
            expect(surfaceOf(tester).color!.a, 0, reason: '$name fill');
            expect(border.borderColor, isNull, reason: name);
            expect(border.bottomBorderColor, c.neutralStrokeAccessible);
        }
        expect(
          border.bottomBorderWidth,
          FluentStroke.thin,
          reason: '$name: the bottom border is 1px',
        );
      }
    });

    testWidgets('Transparent is square, the field and its focus bar both', (
      tester,
    ) async {
      // `underline` sets the root's border-radius to 0, and its `::after`'s.
      await pump(
        tester,
        box(appearance: FluentSearchBoxAppearance.transparent),
      );
      await tester.pumpAndSettle();
      expect(borderOf(tester).radius, BorderRadius.zero);
      expect(surfaceOf(tester).borderRadius, BorderRadius.zero);
      expect(underlineOf(tester).borderRadius, BorderRadius.zero);
    });

    testWidgets('the bottom border ramps with hover on Outline and '
        'Transparent', (tester) async {
      final c = light.colors;
      final mouse = await mouseAt(tester, Offset.zero);
      for (final appearance in <FluentSearchBoxAppearance>[
        FluentSearchBoxAppearance.outline,
        FluentSearchBoxAppearance.transparent,
      ]) {
        await pump(tester, box(appearance: appearance));
        expect(bottomOf(tester), c.neutralStrokeAccessible);

        await mouse.moveTo(tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expect(
          bottomOf(tester),
          c.neutralStrokeAccessibleHover,
          reason: '${appearance.name}: `underlineInteractive` ramps it too',
        );
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the bottom colour meets the sides on the CSS corner '
        'diagonal', (tester) async {
      // A browser splits two border colours along the line from the border
      // box's corner to the padding box's: 45° here. At DPR 4, device pixel
      // (7, 4h − 6) is below the diagonal on the bottom-left arc and
      // (4, 4h − 8) above it — the same probe points as FluentInput's test.
      const boundary = Key('boundary');
      await pump(tester, RepaintBoundary(key: boundary, child: box()));
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

    testWidgets('the glyphs are the react-icons paths', (tester) async {
      // SearchRegular's ring is r 6.5 outside and 5.5 inside about (8.5, 8.5)
      // on the 20-unit box: (8.5, 2.5) is ink, (8.5, 3.75) is the hole. The
      // stroked approximation this replaced had them the other way round.
      const boundary = Key('glyph');
      await tester.pumpWidget(
        const Center(
          child: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: Color(0xFFFFFFFF),
              child: CustomPaint(
                size: Size.square(20),
                painter: FluentSearchBoxGlyphPainter(
                  glyph: FluentSearchBoxGlyph.search,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
        ),
      );
      final pixels = (await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(find.byKey(boundary))
            .toImage(pixelRatio: 4);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;
      int red(double x, double y) =>
          pixels.getUint8((((y * 4).floor() * 80) + (x * 4).floor()) * 4);
      expect(red(8.5, 2.5), lessThan(40), reason: 'on the ring');
      expect(red(8.5, 3.75), greaterThan(215), reason: 'inside the ring');
    });

    testWidgets('the focus underline matches the InFocus rectangle', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Outline',
        'Size': 'Medium',
        'State': 'Focus',
      });
      final inFocus = variant.part('InFocus');

      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(underlineOf(tester).color, inFocus.fill);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Transform),
              ),
            )
            .height,
        inFocus.size.height,
        reason: 'the focus bar is 2 tall',
      );
      expect(underlineOf(tester).borderRadius, inFocus.radius);
    });

    testWidgets('focus moves the border to the Pressed stop, hovered or not', (
      tester,
    ) async {
      // `:active,:focus-within` is one rule, sorted after `:hover`.
      final c = light.colors;
      for (final appearance in <FluentSearchBoxAppearance>[
        FluentSearchBoxAppearance.outline,
        FluentSearchBoxAppearance.transparent,
      ]) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(tester, box(appearance: appearance, focusNode: node));
        node.requestFocus();
        await tester.pumpAndSettle();

        final outline = appearance == FluentSearchBoxAppearance.outline;
        void expectPressedRamp(String when) {
          expect(
            borderOf(tester).borderColor,
            outline ? c.neutralStroke1Pressed : null,
            reason: '${appearance.name} $when: sides',
          );
          expect(
            bottomOf(tester),
            c.neutralStrokeAccessiblePressed,
            reason: '${appearance.name} $when: bottom',
          );
        }

        expectPressedRamp('focused');
        final mouse = await mouseAt(tester, tester.getCenter(find.byKey(key)));
        await tester.pumpAndSettle();
        expectPressedRamp('focused and hovered');
        await mouse.removePointer();
      }
    });

    testWidgets('focus lifts the filled border to Interactive', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        box(
          appearance: FluentSearchBoxAppearance.filledDarker,
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(
        borderOf(tester).borderColor,
        light.colors.transparentStrokeInteractive,
      );
    });

    testWidgets('a press holds the Pressed border, and the Pressed bar when '
        'focused', (tester) async {
      final c = light.colors;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node), width: 200);
      final origin = tester.getTopLeft(find.byKey(key));

      // Held on the root padding while unfocused: `:active` alone.
      final press = await tester.startGesture(
        origin + const Offset(4, 16),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(bottomOf(tester), c.neutralStrokeAccessiblePressed);
      await press.up();
      await tester.pump();
      expect(node.hasFocus, isFalse);

      // A right press takes `:active` too (Chrome, root padding and icon,
      // unfocused), unlike the Combobox family.
      final right = await tester.startGesture(
        origin + const Offset(4, 16),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      expect(bottomOf(tester), c.neutralStrokeAccessiblePressed);
      await right.up();
      await tester.pump();

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(underlineOf(tester).color, c.compoundBrandStroke);
      final held = await tester.startGesture(
        tester.getCenter(find.byType(EditableText)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      // `:focus-within:active::after`.
      expect(underlineOf(tester).color, c.compoundBrandStrokePressed);
      await held.up();
      await tester.pump();
      expect(underlineOf(tester).color, c.compoundBrandStroke);

      // A right press on the focused text holds it too (Chrome).
      final heldRight = await tester.startGesture(
        tester.getCenter(find.byType(EditableText)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      expect(underlineOf(tester).color, c.compoundBrandStrokePressed);
      await heldRight.up();
      await tester.pump();
      expect(underlineOf(tester).color, c.compoundBrandStroke);
    });

    testWidgets(
      'a mouse press in the input focuses at once; on the icon it does not',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        // Chrome focuses the <input> on mousedown for every button, caret at
        // the press, so the bar grows under a held press. The search icon and
        // the root padding are not the input and leave focus alone
        // (`extra.json`). A right press that moves focus drops `:active`.
        final c = light.colors;
        for (final button in <int>[
          kPrimaryMouseButton,
          kMiddleMouseButton,
          kSecondaryMouseButton,
        ]) {
          final node = FocusNode();
          final controller = TextEditingController(text: 'hello world');
          await pump(
            tester,
            box(focusNode: node, controller: controller),
            width: 200,
          );
          final icon = await tester.startGesture(
            tester.getTopLeft(find.byKey(key)) + const Offset(18, 16),
            kind: PointerDeviceKind.mouse,
            buttons: button,
          );
          await tester.pump();
          expect(node.hasFocus, isFalse, reason: 'button $button: the icon');
          await icon.up();
          await tester.pump();

          final press = await tester.startGesture(
            tester.getTopLeft(find.byType(EditableText)) + const Offset(2, 8),
            kind: PointerDeviceKind.mouse,
            buttons: button,
          );
          await tester.pump();
          expect(node.hasFocus, isTrue, reason: 'button $button: focused held');
          expect(
            controller.selection,
            const TextSelection.collapsed(offset: 0),
            reason: 'button $button: caret at the press',
          );
          expect(
            borderOf(tester).borderColor,
            c.neutralStroke1Pressed,
            reason: 'focused holds the Pressed stop, pressed or not',
          );
          if (button == kSecondaryMouseButton) {
            expect(
              underlineOf(tester).color,
              c.compoundBrandStroke,
              reason: 'a right press that moved focus is not :active',
            );
          }
          await press.up();
          await tester.pumpWidget(const SizedBox());
          node.dispose();
          controller.dispose();
        }
      },
    );

    testWidgets('re-enabled under a resting mouse, it hovers and presses', (
      tester,
    ) async {
      // Chrome: a disabled root still matches `:hover`, and `:active` under a
      // held press, so dropping `disabled` shows both at once, unmoved.
      final c = light.colors;
      final mouse = await mouseAt(tester, Offset.zero);
      await pump(tester, box(enabled: false), width: 200);
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStrokeDisabled);
      await pump(tester, box(), width: 200);
      expect(borderOf(tester).borderColor, c.neutralStroke1Hover);

      // Held on the root padding, where only the root itself is hit.
      await pump(tester, box(enabled: false), width: 200);
      final press = await tester.startGesture(
        tester.getTopLeft(find.byKey(key)) + const Offset(4, 16),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStrokeDisabled);
      await pump(tester, box(), width: 200);
      expect(borderOf(tester).borderColor, c.neutralStroke1Pressed);
      await press.cancel();
      await tester.pump();
      expect(borderOf(tester).borderColor, c.neutralStroke1Hover);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a box removed mid-press takes the release quietly', (
      tester,
    ) async {
      // The release still reaches the detached `Listener`, after `dispose`.
      await pump(tester, box());
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

    testWidgets('error strokes the box in colorPaletteRedBorder2 until '
        'focused', (tester) async {
      final c = light.colors;
      final red = c.palette.stroke2Rest(FluentPaletteFamily.red)!;
      for (final appearance in FluentSearchBoxAppearance.values) {
        final node = FocusNode();
        addTearDown(node.dispose);
        await pump(
          tester,
          box(appearance: appearance, error: true, focusNode: node),
        );
        final name = appearance.name;
        expect(
          borderOf(tester).borderColor,
          appearance == FluentSearchBoxAppearance.transparent ? null : red,
          reason: '$name: sides',
        );
        expect(bottomOf(tester), red, reason: '$name: bottom');

        // `:not(:focus-within)`: a focused invalid box takes the focus ramp.
        node.requestFocus();
        await tester.pumpAndSettle();
        expect(bottomOf(tester), isNot(red), reason: '$name: focused');
      }
    });

    testWidgets('disabled Transparent keeps only its bottom border', (
      tester,
    ) async {
      await pump(
        tester,
        box(appearance: FluentSearchBoxAppearance.transparent, enabled: false),
      );
      final border = borderOf(tester);
      expect(border.borderColor, isNull);
      expect(border.bottomBorderColor, light.colors.neutralStrokeDisabled);
      expect(border.radius, BorderRadius.zero);
    });

    testWidgets('read only looks exactly like rest and still selects', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);
      await pump(
        tester,
        box(readOnly: true, controller: controller, focusNode: node),
      );
      expect(borderOf(tester).borderColor, light.colors.neutralStroke1);

      // Upstream: a double-click selects the word, and the click focuses it.
      // On the word itself, a few pixels into the text.
      final at =
          tester.getRect(find.byType(EditableText)).centerLeft +
          const Offset(10, 0);
      final mouse = await mouseAt(tester, at);
      await mouse.down(at);
      await mouse.up();
      await tester.pump(const Duration(milliseconds: 50));
      await mouse.down(at);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 6),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).selectionColor,
        isNotNull,
      );
    });

    testWidgets('the caret is 1px, like the browser caret', (tester) async {
      await pump(tester, box());
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).cursorWidth,
        FluentStroke.thin,
      );
    });
  });

  group('motion', () {
    testWidgets('the underline scales in over 200ms and out over 50ms', (
      tester,
    ) async {
      // useInputStyles.styles.ts: ::after transform scaleX, durationNormal in,
      // durationUltraFast out. It is the only transition either the SearchBox
      // or the Input styles file declares.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      await tester.pumpAndSettle();
      expect(underlineScaleOf(tester), 0, reason: 'hidden at rest');

      node.requestFocus();
      // Two pumps: the first applies the focus change, the second is the first
      // frame built with it — which is where the tween starts.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = underlineScaleOf(tester);
      expect(midway, greaterThan(0), reason: 'must be mid-tween, not instant');
      expect(midway, lessThan(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(underlineScaleOf(tester), 1);

      node.unfocus();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 25));
      expect(
        underlineScaleOf(tester),
        greaterThan(0),
        reason: 'the exit is four times faster, but still a tween',
      );
      await tester.pump(const Duration(milliseconds: 25));
      expect(underlineScaleOf(tester), 0);
    });

    testWidgets('reduced motion lands the underline immediately', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node), reducedMotion: true);
      await tester.pumpAndSettle();

      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(underlineScaleOf(tester), 1);
    });

    testWidgets('the surface never animates', (tester) async {
      // Neither styles file transitions background, border or colour — the
      // hover rule changes on the frame the pointer arrives.
      await pump(tester, box());
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(borderOf(tester).borderColor, theme.colors.neutralStroke1Hover);
      expect(bottomOf(tester), theme.colors.neutralStrokeAccessibleHover);
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
        FluentSearchBoxTheme(
          style: FluentSearchBoxStyle.from(backgroundColor: themed),
          child: box(
            style: FluentSearchBoxStyle.from(backgroundColor: explicit),
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
        FluentSearchBoxTheme(
          style: FluentSearchBoxStyle.from(backgroundColor: themed),
          child: box(),
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
        box(
          appearance: FluentSearchBoxAppearance.filledDarker,
          style: FluentSearchBoxStyle.from(gap: 40),
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        surfaceOf(tester).color,
        theme.colors.neutralBackground3,
        reason: 'overriding the gap must not drop the fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSearchBoxBaseState(
        enabled: true,
        focused: false,
        field: SizedBox(height: 20),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSearchBox(
            base,
            FluentSearchBoxStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allMedium,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, mine);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSearchBoxState(
        field: const SizedBox(height: 20),
        appearance: FluentSearchBoxAppearance.filledDarker,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentSearchBoxStyle(state, theme).merge(
        FluentSearchBoxStyle.from(borderRadius: FluentRadius.allCircular),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSearchBox(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      final surface = decorationsOf(tester).first;
      expect(surface.color, theme.colors.neutralBackground3);
      expect(surface.borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the search box', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralBackground3: magenta},
            child: Center(
              child: SizedBox(
                width: 468,
                child: box(appearance: FluentSearchBoxAppearance.filledDarker),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(surfaceOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border on any appearance', (
      tester,
    ) async {
      for (final appearance in FluentSearchBoxAppearance.values) {
        await pump(
          tester,
          box(appearance: appearance),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        );
        await tester.pumpAndSettle();

        if (appearance == FluentSearchBoxAppearance.transparent) {
          // No side borders by design; the bottom one is the whole component,
          // and it must still be opaque.
          expect(bottomOf(tester)!.a, 1.0, reason: '${appearance.name} rule');
        } else {
          // transparentStroke resolves to an opaque highlight in high contrast,
          // which is the only thing outlining a filled search box there.
          expect(
            borderOf(tester).borderColor!.a,
            1.0,
            reason: '${appearance.name} border',
          );
        }
      }
    });
  });

  group('behaviour', () {
    testWidgets('typing reports every edit and Enter submits', (tester) async {
      final changes = <String>[];
      final submitted = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        box(
          focusNode: node,
          onChanged: changes.add,
          onSubmitted: submitted.add,
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.enterText(find.byType(EditableText), 'fluent');
      await tester.pump();
      expect(changes, <String>['fluent']);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submitted, <String>['fluent']);
    });

    testWidgets('the placeholder shows only while the value is empty', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, box(controller: controller));

      expect(find.text('Search'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('the clear button appears with focus, clears, and gives focus '
        'back', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);
      var cleared = 0;

      await pump(
        tester,
        box(controller: controller, focusNode: node, onClear: () => cleared++),
      );

      // Both sources gate the clear affordance on focus, not on the value:
      // upstream collapses `contentAfter` whenever `!focused`, and Figma hides
      // `Icon after container` on every Rest and Hover variant.
      expect(find.bySemanticsLabel('Clear'), findsNothing);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();
      expect(controller.text, isEmpty);
      expect(cleared, 1);
      expect(node.hasFocus, isTrue, reason: 'focus returns to the field');
    });

    testWidgets('Escape clears the field', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(tester, box(controller: controller, focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('the clear button stays out of the tab order', (tester) async {
      // Upstream gives the dismiss slot `tabIndex: -1`; Escape is the keyboard
      // path, not a second tab stop between the field and whatever follows it.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node));
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FluentInteractive>(find.byType(FluentInteractive))
            .focusNode!
            .skipTraversal,
        isTrue,
      );
    });

    testWidgets('only the input box takes focus from a click', (tester) async {
      // Upstream (medium, 200 wide): x 4 is root padding and x 18 the search
      // icon — a plain <span>, so the field stays unfocused; x 30 is the
      // <input>'s own padding-left, which focuses it.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, box(focusNode: node), width: 200);
      final origin = tester.getTopLeft(find.byKey(key));

      for (final x in <double>[4, 18]) {
        await tester.tapAt(
          origin + Offset(x, 16),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(node.hasFocus, isFalse, reason: 'x $x');
      }
      // A browser decides at mousedown: down on the input's padding-left,
      // released after drifting onto the icon, still focuses.
      final drift = await tester.startGesture(
        origin + const Offset(30, 16),
        kind: PointerDeviceKind.mouse,
      );
      await drift.moveBy(const Offset(-2, 0));
      await drift.up();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'x 30, released at x 28');

      // Unfocused, the root's padding-right is the input's own (x 195).
      node.unfocus();
      await tester.pumpAndSettle();
      await tester.tapAt(
        origin + const Offset(195, 16),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue, reason: 'x 195');
    });

    testWidgets('RTL clicks mirror: only the input box takes focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: FluentSearchBox(key: key, focusNode: node),
        ),
        width: 200,
      );
      final origin = tester.getTopLeft(find.byKey(key));
      // Root padding, then the icon: nothing.
      for (final x in <double>[196, 182]) {
        await tester.tapAt(
          origin + Offset(x, 16),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(node.hasFocus, isFalse, reason: 'x $x');
      }
      // The input's padding on the icon side, then (unfocused) the one that
      // reaches the far border.
      for (final x in <double>[168, 4]) {
        node.unfocus();
        await tester.pumpAndSettle();
        await tester.tapAt(
          origin + Offset(x, 16),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(node.hasFocus, isTrue, reason: 'x $x');
      }
    });

    testWidgets('the text cursor covers the input box only', (tester) async {
      // Upstream: root padding and icon `auto`, the <input> `text`.
      await pump(tester, box(), width: 200);
      final origin = tester.getTopLeft(find.byKey(key));
      final mouse = await mouseAt(tester, origin + const Offset(4, 16));
      await tester.pump();
      MouseCursor cursor() =>
          RendererBinding.instance.mouseTracker
          // A test mouse is device 1.
          .debugDeviceActiveCursor(1)!;
      expect(cursor(), SystemMouseCursors.basic, reason: 'root padding');
      await mouse.moveTo(origin + const Offset(18, 16));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.basic, reason: 'search icon');
      await mouse.moveTo(origin + const Offset(30, 3));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.text, reason: 'input padding-left');
      await mouse.moveTo(origin + const Offset(100, 16));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.text, reason: 'input text');
      // Unfocused, the root has no padding-right: the input's own reaches
      // the border.
      await mouse.moveTo(origin + const Offset(195, 16));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.text, reason: 'input padding-right');
    });

    testWidgets('disabled is a real state', (tester) async {
      final controller = TextEditingController(text: 'fluent');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        box(
          enabled: false,
          controller: controller,
          focusNode: node,
          appearance: FluentSearchBoxAppearance.outline,
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      // The disabled ramp replaces the enabled one wholesale rather than
      // dimming it — useInputStyles.styles.ts `disabled`.
      expect(surfaceOf(tester).color!.a, 0, reason: 'transparent fill');
      expect(borderOf(tester).borderColor, theme.colors.neutralStrokeDisabled);
      expect(
        bottomOf(tester),
        theme.colors.neutralStrokeDisabled,
        reason: 'StrokeDisabled on every side, the bottom included',
      );
      expect(find.bySemanticsLabel('Clear'), findsNothing);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );

      // A disabled box must not adopt the hover ramp either.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(borderOf(tester).borderColor, theme.colors.neutralStrokeDisabled);
      // Over the text line itself, where `EditableText` has its own region.
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.forbidden,
        reason: '`not-allowed` everywhere, the text included',
      );
    });

    testWidgets('a disabled box leaves the tap to its ancestors', (
      tester,
    ) async {
      // No recogniser of its own may join the arena, or it wins the tap an
      // enclosing row or card is waiting for.
      var taps = 0;
      await pump(
        tester,
        GestureDetector(onTap: () => taps++, child: box(enabled: false)),
      );
      await tester.tap(find.byKey(key), kind: PointerDeviceKind.mouse);
      expect(taps, 1);
    });

    testWidgets('the disabled focus underline never shows', (tester) async {
      // `disabled` sets `::after { content: unset }` upstream — the bar is gone,
      // not merely unscaled.
      await pump(tester, box(enabled: false));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
        findsNothing,
      );
    });

    testWidgets('it announces itself as a named text field', (tester) async {
      await pump(
        tester,
        const FluentSearchBox(
          key: key,
          semanticLabel: 'Search files',
          placeholder: 'Search',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(label: 'Search files', isTextField: true, isEnabled: true),
      );
    });
  });

  testWidgets('the bordered box fills the control height at every size', (
    tester,
  ) async {
    const heights = <FluentSearchBoxSize, double>{
      FluentSearchBoxSize.small: 24,
      FluentSearchBoxSize.medium: 32,
      FluentSearchBoxSize.large: 40,
    };

    for (final entry in heights.entries) {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: FluentSearchBox(key: const Key('sb'), size: entry.key),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('sb')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        box.height,
        entry.value,
        reason: '${entry.key.name}: the decorated surface must fill the slot',
      );
      // The bar sits ON the box's bottom edge, not below it.
      final bar = tester.getRect(
        find.descendant(
          of: find.byKey(const Key('sb')),
          matching: find.byType(FluentInputFocusUnderline),
        ),
      );
      expect(
        bar.bottom,
        box.bottom,
        reason: '${entry.key.name}: the underline must not detach',
      );
    }
  });
  testWidgets('a tight parent height stretches the box, bar and all', (
    tester,
  ) async {
    // A CSS `height` sizes the border box, and `::after` sits on its bottom.
    await pump(
      tester,
      const SizedBox(height: 60, child: FluentSearchBox(key: key)),
    );
    final painted = find.descendant(
      of: find.byKey(key),
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
      ),
    );
    final bar = find.descendant(
      of: find.byKey(key),
      matching: find.byType(FluentInputFocusUnderline),
    );
    expect(tester.getRect(painted).height, 60);
    expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
  });
  // One shape, one implementation: the focus bar is `FluentInputFocusUnderline`
  // (input.dart), which is where the `max(thickness, radius)` + clip trick that
  // keeps a 4px corner on a 2px bar lives.
  testWidgets('the focus bar comes from the shared primitive', (tester) async {
    await tester.pumpWidget(
      const FluentApp(
        home: Center(
          child: SizedBox(
            width: 300,
            child: FluentSearchBox(key: Key('sb-primitive')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('sb-primitive')),
        matching: find.byType(FluentInputFocusUnderline),
      ),
      findsOneWidget,
      reason: 'one shape, one implementation — see input.dart',
    );
  });
}
