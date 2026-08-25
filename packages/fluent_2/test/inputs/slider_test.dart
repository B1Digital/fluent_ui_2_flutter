import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSlider` paints its rail, ticks and thumb rather than composing them,
/// so there is no `DecoratedBox` to read a colour back from. `expectSpec` is
/// therefore unusable here: every assertion reads [FluentSliderPainter]'s
/// public fields instead, which is exactly why they are public.
///
/// The numbers come from `test/fixtures/slider.json` — the Figma `Slider` set,
/// 10 variants — and specifically from each variant's **parts**, since the
/// variant frame itself paints nothing. Figma's layers map onto the painter as:
/// `Rail-fill` → rail, `Track-fill` → progress, `Thumb` → thumb fill and
/// outline, `Thumb-inner` → the coloured disc.
void main() {
  const key = Key('slider');
  final spec = loadSpec('slider');

  /// Compares a painted colour with the value Figma resolved.
  ///
  /// A fully transparent Fluent token is compared on alpha only: Figma cannot
  /// store a colour without an RGB triple and records it as transparent
  /// *white*, where core stores CSS's transparent *black*. Both are invisible;
  /// see `doc/token-divergences.md`.
  void expectFill(Color? actual, Color? expected, String label) {
    expect(expected, isNotNull, reason: '$label: the fixture has no fill');
    expect(actual, isNotNull, reason: '$label: nothing was painted');
    if (expected!.a == 0) {
      expect(actual!.a, 0, reason: '$label alpha');
      return;
    }
    expect(actual!.toARGB32(), expected.toARGB32(), reason: label);
  }

  Future<void> pump(
    WidgetTester tester,
    Widget slider, {
    FluentThemeData? theme,
    double width = 200,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: width, child: slider),
        ),
      ),
    ),
  );

  /// The slider's own painter, skipping the focus ring's `CustomPaint`.
  FluentSliderPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentSliderPainter>()
      .first;

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('geometry, every size, against the Figma parts', () {
    const sizes = {
      FluentSliderSize.medium: 'Medium',
      FluentSliderSize.small: 'Small',
    };

    for (final entry in sizes.entries) {
      testWidgets('${entry.key.name} thumb, rail and height', (tester) async {
        final variant = spec.variant({'Size': entry.value, 'State': 'Rest'});
        final rail = variant.part('Rail-fill');
        final thumb = variant.part('Thumb');
        final disc = variant.part('Thumb-inner');

        await pump(
          tester,
          FluentSlider(key: key, value: 50, size: entry.key, onChanged: (_) {}),
        );

        final painter = painterOf(tester);
        expect(painter.railThickness, rail.size.height, reason: 'rail');
        expect(painter.railRadius, rail.radius, reason: 'rail radius');
        // Figma's Thumb frame is the fill box and its stroke is aligned
        // OUTSIDE, so the diameter the painter needs is the frame plus a
        // stroke on each side: 18 + 2 = 20, 14 + 2 = 16.
        expect(
          painter.thumbSize,
          thumb.size.width + 2 * thumb.strokeWidth!,
          reason: 'thumb outer diameter',
        );
        expect(
          painter.thumbBorderWidth,
          thumb.strokeWidth,
          reason: 'thumb outline — a flat 1, not thumbSize * 0.05',
        );
        expect(
          painter.thumbInnerRadius,
          disc.size.width / 2,
          reason: 'centre disc — 12 and 10 across, not thumbSize * 0.3',
        );
        // The rail stops `Spacing/Horizontal/S` short of each end in BOTH
        // sizes; it is not half a thumb.
        expect(
          painter.railInset,
          variant.part('Rail').padding!.left,
          reason: 'rail inset',
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: 'control height — 24 in both sizes',
        );
      });
    }

    test('the style carries Figma\'s 120 x 24 frame', () {
      // Recorded on the style rather than asserted on the box: `width:
      // double.infinity` means the rail always fills the width it is given,
      // and no ConstrainedBox can widen a parent's tight constraint anyway.
      final variant = spec.variant({'Size': 'Medium', 'State': 'Rest'});
      final style = resolveFluentSliderStyle(
        resolveFluentSliderState(value: 0),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(style.minimumSize!.resolve(const <WidgetState>{}), variant.size);
    });

    testWidgets('the rail fills the width it is given', (tester) async {
      await pump(
        tester,
        FluentSlider(key: key, value: 0, onChanged: (_) {}),
        width: 340,
      );
      expect(tester.getSize(find.byKey(key)).width, 340);
    });

    testWidgets('the thumb stays inside the control at both extremes', (
      tester,
    ) async {
      // useSliderStyles.styles.ts clamps the thumb — and only the thumb; the
      // progress fill is not clamped — with
      // `clamp(innerThumbRadius, progress, calc(100% - innerThumbRadius))`.
      // Live probe components-slider--default after Home: root x=60 w=129,
      // rail x=70 w=109, thumb x=66 w=20, so the thumb's centre is rail.left
      // + 6 and its left edge is 6 INSIDE the root. Unclamped, a medium thumb
      // centred on the rail's end hangs 2px outside the box.
      const rail = Rect.fromLTWH(FluentSpacing.s, 10, 184, 4);
      const size = Size(200, 24);

      for (final (fraction, expected) in <(double, double)>[
        (0, rail.left + 6),
        (1, rail.right - 6),
      ]) {
        final recorder = _ThumbRecorder();
        FluentSliderPainter(
          fraction: fraction,
          textDirection: TextDirection.ltr,
          railThickness: rail.height,
          railInset: rail.left,
          railRadius: FluentRadius.allSmall,
          thumbSize: 20,
          thumbInnerRadius: 6,
          thumbBorderWidth: FluentStroke.thin,
          thumbInnerColor: const Color(0xFFFFFFFF),
        ).paint(recorder, size);
        expect(recorder.centre!.dx, expected, reason: 'fraction $fraction');
        expect(
          recorder.centre!.dx - 10,
          greaterThanOrEqualTo(0),
          reason: 'the thumb hangs off the left of the control box',
        );
        expect(
          recorder.centre!.dx + 10,
          lessThanOrEqualTo(size.width),
          reason: 'the thumb hangs off the right of the control box',
        );
      }
    });
  });

  group('every interaction state selects the token Figma names', () {
    /// Every colour the painter resolved, against the four Figma layers.
    void expectVariant(FluentSliderPainter painter, String state) {
      final variant = spec.variant({'Size': 'Medium', 'State': state});
      expectFill(painter.railColor, variant.part('Rail-fill').fill, 'rail');
      expectFill(
        painter.progressColor,
        variant.part('Track-fill').fill,
        'progress',
      );
      expectFill(
        painter.thumbColor,
        variant.part('Thumb-inner').fill,
        'thumb disc',
      );
      expectFill(
        painter.thumbInnerColor,
        variant.part('Thumb').fill,
        'thumb fill',
      );
      expectFill(
        painter.thumbBorderColor,
        variant.part('Thumb').stroke,
        'thumb outline',
      );
    }

    testWidgets('rest', (tester) async {
      await pump(tester, FluentSlider(key: key, value: 50, onChanged: (_) {}));
      final painter = painterOf(tester);
      expectVariant(painter, 'Rest');
      // The same values, named: nothing here may be a literal or a computed
      // shade of another token.
      final theme = light();
      expect(painter.railColor, theme.colors.neutralStrokeAccessible);
      expect(painter.progressColor, theme.colors.compoundBrandBackground);
      expect(painter.thumbColor, theme.colors.compoundBrandBackground);
      expect(painter.thumbInnerColor, theme.colors.neutralBackground1);
      expect(painter.thumbBorderColor, theme.colors.neutralStroke1);
    });

    testWidgets('hover, and it is INSTANT — Figma declares no transition', (
      tester,
    ) async {
      // Neither the Figma set nor useSliderStyles.styles.ts carries a duration
      // or curve anywhere. A tween here would be an invention, so one frame
      // must be enough.
      await pump(tester, FluentSlider(key: key, value: 50, onChanged: (_) {}));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expectVariant(painterOf(tester), 'Hover');
      expect(
        painterOf(tester).thumbColor,
        light().colors.compoundBrandBackgroundHover,
        reason: 'the hover token must land on the first frame',
      );
    });

    testWidgets('pressed', (tester) async {
      await pump(tester, FluentSlider(key: key, value: 50, onChanged: (_) {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      addTearDown(gesture.up);
      await tester.pump();
      expectVariant(painterOf(tester), 'Pressed');
      expect(
        painterOf(tester).thumbColor,
        light().colors.compoundBrandBackgroundPressed,
      );
    });

    testWidgets('disabled', (tester) async {
      await pump(tester, const FluentSlider(key: key, value: 50));
      final painter = painterOf(tester);
      expectVariant(painter, 'Disabled');
      final theme = light();
      expect(painter.thumbColor, theme.colors.neutralForegroundDisabled);
      expect(painter.progressColor, theme.colors.neutralForegroundDisabled);
      // Figma disagrees with React twice over here: the rail goes fully
      // transparent rather than to neutralBackgroundDisabled, and the thumb
      // outline is a stroke token rather than a foreground one.
      expect(painter.railColor, theme.colors.transparentStrokeDisabled);
      expect(painter.thumbBorderColor, theme.colors.neutralStrokeDisabled);
    });

    testWidgets('focus repaints nothing but the ring', (tester) async {
      // Figma's Focus variant carries the Rest colours on every layer; only the
      // two rings on the frame differ.
      final rest = spec.variant({'Size': 'Medium', 'State': 'Rest'});
      final focus = spec.variant({'Size': 'Medium', 'State': 'Focus'});
      for (final layer in ['Rail-fill', 'Track-fill', 'Thumb', 'Thumb-inner']) {
        expect(
          focus.part(layer).tokens,
          rest.part(layer).tokens,
          reason: layer,
        );
      }
      expect(focus.token('strokes'), 'Neutral/Stroke/Focus/2/Rest');
    });
  });

  group('continuous and stepped', () {
    testWidgets('a continuous rail draws no ticks', (tester) async {
      await pump(tester, FluentSlider(key: key, value: 50, onChanged: (_) {}));
      expect(painterOf(tester).intervals, isNull);
    });

    testWidgets('a stepped rail ticks once per interval', (tester) async {
      await pump(
        tester,
        FluentSlider(key: key, value: 50, step: 25, onChanged: (_) {}),
      );
      expect(painterOf(tester).intervals, 4);
      expect(painterOf(tester).stepColor, light().colors.neutralBackground1);
    });

    testWidgets('a step larger than the range ticks nothing', (tester) async {
      await pump(
        tester,
        FluentSlider(key: key, value: 0, step: 200, onChanged: (_) {}),
      );
      expect(painterOf(tester).intervals, isNull);
    });

    testWidgets('a drag snaps to the step', (tester) async {
      final reported = <double>[];
      await pump(
        tester,
        FluentSlider(key: key, value: 0, step: 25, onChanged: reported.add),
      );
      // width 200, rail inset 8 → the rail runs from x=8 to x=192. x=100 is
      // dead centre, which snaps to 50.
      await tester.tapAt(
        tester.getTopLeft(find.byKey(key)) + const Offset(100, 12),
      );
      await tester.pump();
      expect(reported, <double>[50]);
    });

    testWidgets('the fraction clamps rather than overflowing the rail', (
      tester,
    ) async {
      await pump(tester, FluentSlider(key: key, value: 400, onChanged: (_) {}));
      expect(painterOf(tester).fraction, 1);
    });
  });

  group('pointer input', () {
    testWidgets('a drag reports the value under the pointer', (tester) async {
      final reported = <double>[];
      await pump(
        tester,
        FluentSlider(key: key, value: 0, onChanged: reported.add),
      );

      final origin = tester.getTopLeft(find.byKey(key));
      final gesture = await tester.startGesture(origin + const Offset(8, 12));
      await tester.pump();
      await gesture.moveTo(origin + const Offset(100, 12));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(reported.last, closeTo(50, 0.001));
    });

    testWidgets('the rail runs right to left under RTL', (tester) async {
      final reported = <double>[];
      await pump(
        tester,
        FluentSlider(key: key, value: 0, onChanged: reported.add),
        direction: TextDirection.rtl,
      );
      // x=8 is the rail's own start, which under RTL is the maximum.
      final origin = tester.getTopLeft(find.byKey(key));
      await tester.tapAt(origin + const Offset(8, 12));
      await tester.pump();
      expect(reported.single, closeTo(100, 0.001));
    });

    testWidgets('a touch drag inside a horizontal scroll view still reports', (
      tester,
    ) async {
      final reported = <double>[];
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: SizedBox(
              width: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  SizedBox(
                    width: 200,
                    child: FluentSlider(
                      key: key,
                      value: 0,
                      onChanged: reported.add,
                    ),
                  ),
                  const SizedBox(width: 400),
                ],
              ),
            ),
          ),
        ),
      );

      final origin = tester.getTopLeft(find.byKey(key));
      final gesture = await tester.startGesture(origin + const Offset(8, 12));
      await tester.pump();
      await gesture.moveTo(origin + const Offset(100, 12));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // The regression this guards: with a GestureDetector's horizontal drag
      // recognizer the ancestor ListView won the arena for a *touch* pointer
      // and scrolled instead. Mouse never showed it, because Flutter leaves
      // mouse out of ScrollBehavior.dragDevices.
      expect(
        reported.last,
        closeTo(50, 0.001),
        reason: 'the drag reached the slider, not the scroll view',
      );
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
        reason: 'and the list did not scroll under it',
      );
    });
  });

  group('keyboard', () {
    testWidgets('arrows move by one step and Home/End jump to the ends', (
      tester,
    ) async {
      final reported = <double>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 50,
          step: 10,
          focusNode: node,
          onChanged: reported.add,
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();

      expect(reported, <double>[60, 40, 0, 100]);
    });

    testWidgets('a continuous slider still steps by one', (tester) async {
      final reported = <double>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 50,
          focusNode: node,
          onChanged: reported.add,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(reported, <double>[51]);
    });

    testWidgets('keyboard focus raises the ring, and it does not animate', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSlider(key: key, value: 50, focusNode: node, onChanged: (_) {}),
      );
      FluentFocusRingPainter ringOf() => tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.foregroundPainter)
          .whereType<FluentFocusRingPainter>()
          .first;

      expect(ringOf().visible, isFalse);
      // Keyboard-visible focus, not pointer focus: the ring must not appear
      // just because a click landed on the control.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      node.requestFocus();
      await tester.pump();
      expect(ringOf().visible, isTrue);
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
        FluentSliderTheme(
          style: FluentSliderStyle.from(thumbColor: themed),
          child: FluentSlider(
            key: key,
            value: 50,
            style: FluentSliderStyle.from(thumbColor: explicit),
            onChanged: (_) {},
          ),
        ),
      );
      expect(painterOf(tester).thumbColor, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSliderTheme(
          style: FluentSliderStyle.from(thumbColor: themed),
          child: FluentSlider(key: key, value: 50, onChanged: (_) {}),
        ),
      );
      expect(painterOf(tester).thumbColor, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 50,
          style: FluentSliderStyle.from(railThickness: 12),
          onChanged: (_) {},
        ),
      );
      expect(painterOf(tester).railThickness, 12);
      expect(
        painterOf(tester).progressColor,
        light().colors.compoundBrandBackground,
        reason: 'overriding the rail must not drop the brand progress',
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
          child: buildFluentSlider(
            const FluentSliderBaseState(
              value: 25,
              min: 0,
              max: 100,
              enabled: true,
            ),
            FluentSliderStyle.from(
              thumbColor: mine,
              thumbSize: 20,
              railThickness: 4,
              minimumSize: const Size(120, 32),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(painterOf(tester).thumbColor, mine);
      expect(painterOf(tester).fraction, 0.25);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSliderState(value: 50);
      final theme = light();
      final adjusted = resolveFluentSliderStyle(
        state,
        theme,
      ).merge(FluentSliderStyle.from(railThickness: 8));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSlider(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(painterOf(tester).railThickness, 8);
      expect(
        painterOf(tester).progressColor,
        theme.colors.compoundBrandBackground,
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the slider', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandBackground: magenta},
            child: Center(
              child: SizedBox(
                width: 200,
                child: FluentSlider(key: key, value: 50, onChanged: (_) {}),
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).thumbColor, magenta);
      expect(painterOf(tester).progressColor, magenta);
    });

    testWidgets('high contrast leaves nothing invisible', (tester) async {
      await pump(
        tester,
        FluentSlider(key: key, value: 50, step: 25, onChanged: (_) {}),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final painter = painterOf(tester);
      // Figma paints no outline on the rail, so the rail's own fill has to
      // carry it: neutralStrokeAccessible resolves to canvasText here.
      expect(painter.railColor!.a, 1.0, reason: 'rail');
      expect(painter.progressColor!.a, 1.0, reason: 'progress');
      expect(painter.thumbColor!.a, 1.0, reason: 'thumb');
      expect(painter.thumbBorderColor!.a, 1.0, reason: 'thumb outline');
      expect(painter.stepColor!.a, 1.0, reason: 'ticks');
      expect(
        painter.railColor,
        isNot(painter.progressColor),
        reason: 'CanvasText and Highlight must stay distinguishable',
      );
    });
  });

  group('disabled is a real state, not a visual treatment', () {
    testWidgets('it ignores drags, taps and keys', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 50,
          focusNode: node,
          semanticLabel: 'Volume',
        ),
      );

      await tester.tapAt(
        tester.getTopLeft(find.byKey(key)) + const Offset(150, 12),
      );
      await tester.pump();
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(node.hasFocus, isFalse, reason: 'a disabled slider refuses focus');
      expect(painterOf(tester).fraction, 0.5, reason: 'the thumb did not move');
    });

    testWidgets('it does not adopt the hover token', (tester) async {
      await pump(tester, const FluentSlider(key: key, value: 50));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(
        painterOf(tester).thumbColor,
        light().colors.neutralForegroundDisabled,
      );
    });
  });

  group('accessibility', () {
    testWidgets('it announces itself as a slider with a value', (tester) async {
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 40,
          step: 10,
          semanticLabel: 'Volume',
          semanticFormatter: (value) => '${value.round()} percent',
          onChanged: (_) {},
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Volume',
          value: '40 percent',
          increasedValue: '50 percent',
          decreasedValue: '30 percent',
          isSlider: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
    });

    testWidgets('the increase and decrease actions move the value', (
      tester,
    ) async {
      final reported = <double>[];
      await pump(
        tester,
        FluentSlider(
          key: key,
          value: 50,
          step: 10,
          semanticLabel: 'Volume',
          onChanged: reported.add,
        ),
      );
      final node = tester.getSemantics(find.byKey(key));
      final owner = node.owner!;
      owner.performAction(node.id, SemanticsAction.increase);
      owner.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(reported, <double>[60, 40]);
    });

    testWidgets('a disabled slider announces disabled, not just grey', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentSlider(key: key, value: 50, semanticLabel: 'Volume'),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Volume',
          value: '50',
          increasedValue: '51',
          decreasedValue: '49',
          isSlider: true,
          hasEnabledState: true,
          // No increase or decrease action, no focusability: the disabled
          // treatment is a real state change, not a repaint. The bare tap
          // action comes from FluentInteractive's own GestureDetector, which
          // every component in the package shares.
          hasTapAction: false,
        ),
      );
    });
  });
}

/// Captures the centre [FluentSliderPainter] draws its thumb at.
///
/// `implements Canvas` plus `noSuchMethod` rather than a real recording, the
/// same trick `checkbox_test.dart` uses: the point is to read the geometry
/// back, not to rasterise it. The rail, progress and ticks fall through
/// `noSuchMethod`; the thumb's three concentric circles all share one centre,
/// so the first one is the answer.
class _ThumbRecorder implements Canvas {
  Offset? centre;

  @override
  void drawCircle(Offset c, double radius, Paint paint) => centre ??= c;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
