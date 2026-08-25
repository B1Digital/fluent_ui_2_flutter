import 'dart:ui' as ui;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentColorArea` paints its three gradients, its border and its thumb
/// rather than composing them, so there is no `DecoratedBox` to read a colour
/// back from. `expectSpec` is unusable here for a second reason too: ColorPicker
/// is preview-tier upstream (`@fluentui/react-color-picker-preview`) with **no
/// published Figma component set**, so there is no `test/fixtures/color_area
/// .json` and `loadSpec` would throw. Inventing one would be inventing the
/// design.
///
/// The oracle is therefore the upstream source itself —
/// `useColorAreaStyles.styles.ts` and `useColorArea.ts` — which is the same
/// escape hatch `test/support/oracle_fixture.dart` documents for the charts.
/// Every assertion below names the upstream rule it comes from.
void main() {
  const key = Key('area');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget area, {
    FluentThemeData? theme,
    double width = 300,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: width, child: area),
        ),
      ),
    ),
  );

  FluentColorAreaPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentColorAreaPainter>()
      .first;

  /// A colour with a hue that is not grey and not a primary, so a collapsed
  /// hue is obvious.
  const teal = HSVColor.fromAHSV(1, 200, 0.5, 0.5);

  group('geometry, every shape, against upstream\'s styles file', () {
    testWidgets('rounded is borderRadiusMedium and square is none', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      expect(
        painterOf(tester).borderRadius,
        FluentRadius.allMedium,
        reason: 'useColorAreaStyles.styles.ts, useShapeStyles.rounded',
      );

      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          shape: FluentColorPickerShape.square,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      expect(painterOf(tester).borderRadius, BorderRadius.zero);
    });

    testWidgets('the square is 300 tall at minimum and takes the width given', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
        width: 420,
      );
      final painted = tester.getSize(
        find
            .descendant(of: find.byKey(key), matching: find.byType(CustomPaint))
            .first,
      );
      expect(
        painted.height,
        300,
        reason: 'min-height: 300px in the reset styles',
      );
      expect(painted.width, 420, reason: 'the root grid stretches');
      expect(
        tester.getSize(find.byKey(key)).height,
        300 + FluentSpacing.sNudge,
        reason: 'plus margin-bottom: spacingVerticalSNudge',
      );
    });

    testWidgets('the border is 1px neutralStroke1', (tester) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      final painter = painterOf(tester);
      expect(painter.borderWidth, FluentStroke.thin);
      expect(painter.borderColor, light().colors.neutralStroke1);
    });

    testWidgets('the thumb is a 22 disc: 1px grey, 2px surface, the colour', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      final painter = painterOf(tester);
      final colors = light().colors;
      // A content-box 20 plus its 1px border on each side.
      expect(painter.thumbSize, 22);
      expect(painter.thumbBorderWidth, FluentStroke.thin);
      expect(painter.thumbBorderColor, colors.neutralForeground4);
      expect(painter.thumbInnerWidth, FluentStroke.thick);
      expect(painter.thumbInnerColor, colors.neutralBackground1);
      expect(painter.thumbShadow, light().shadow(FluentElevation.shadow4));
      expect(
        painter.thumbColor,
        const HSVColor.fromAHSV(1, 200, 0.5, 0.5).toColor(),
        reason: 'tinycolor(hsv).toRgbString() drops alpha',
      );
    });
  });

  group('the premultiplication trap', () {
    test('the white ramp ends transparent WHITE, not transparent black', () {
      expect(
        FluentColorAreaPainter.saturationRamp,
        const <Color>[Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        reason:
            'CSS interpolates gradients premultiplied and Flutter does not. A '
            '0x00000000 end stop drags the midpoint towards grey and lays a '
            'visible haze down the middle of the square.',
      );
      expect(
        FluentColorAreaPainter.valueRamp,
        const <Color>[Color(0x00000000), Color(0xFF000000)],
        reason: 'transparent black is correct here — the far stop is black',
      );
    });

    test('the painted midpoint is the browser\'s, to within a unit', () async {
      const size = 300.0;
      final recorder = ui.PictureRecorder();
      const FluentColorAreaPainter(
        saturation: 1,
        value: 1,
        // Pure red, so a grey haze is unmissable in the green and blue
        // channels.
        hueColor: Color(0xFFFF0000),
        thumbColor: Color(0xFFFF0000),
        textDirection: TextDirection.ltr,
        borderWidth: 0,
        borderRadius: BorderRadius.zero,
        // No thumb: it would cover the pixels being probed.
        thumbSize: 0,
        thumbBorderWidth: 0,
        thumbInnerWidth: 0,
      ).paint(ui.Canvas(recorder), const Size(size, size));
      final image = await recorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      addTearDown(image.dispose);
      final bytes = (await image.toByteData())!.buffer.asUint8List();

      Color at(int x, int y) {
        final i = (y * size.toInt() + x) * 4;
        return Color.fromARGB(
          bytes[i + 3],
          bytes[i],
          bytes[i + 1],
          bytes[i + 2],
        );
      }

      void expectClose(Color actual, Color expected, String label) {
        expect(
          (actual.r - expected.r).abs(),
          lessThan(0.01),
          reason: '$label r',
        );
        expect(
          (actual.g - expected.g).abs(),
          lessThan(0.01),
          reason: '$label g',
        );
        expect(
          (actual.b - expected.b).abs(),
          lessThan(0.01),
          reason: '$label b',
        );
      }

      expectClose(at(0, 0), const Color(0xFFFFFFFF), 'saturation 0, value 1');
      expectClose(at(299, 0), const Color(0xFFFF0000), 'saturation 1, value 1');
      expectClose(at(150, 299), const Color(0xFF000000), 'value 0');
      // Pixel centre 150.5 of 300 -> white at 1 - 0.501667 = 0.498333 ->
      // round(0.498333 * 255) = 127. With Colors.transparent it would be 0x40.
      expectClose(at(150, 0), const Color(0xFFFF7F7F), 'the midpoint');
    });
  });

  group('the gesture arena', () {
    /// Mounts an area inside a vertical scroll view — the situation on its own
    /// docs page, and the one a bare-widget `tester.drag` cannot see.
    Future<List<HSVColor>> pumpScrolling(WidgetTester tester) async {
      final reported = <HSVColor>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: FluentColorArea(
                    key: key,
                    color: teal,
                    onChanged: reported.add,
                    saturationLabel: 'Saturation',
                    brightnessLabel: 'Brightness',
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      return reported;
    }

    testWidgets('a vertical drag moves the colour and does not scroll', (
      tester,
    ) async {
      final reported = await pumpScrolling(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty, reason: 'the drag reached the area');
      expect(
        reported.last.value,
        lessThan(teal.value),
        reason: 'dragging down lowers brightness',
      );
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
        reason:
            'the page must not scroll under a colour area. A drag recogniser '
            'would not claim the pointer until the slop was exceeded, by which '
            'time the viewport could have won.',
      );
    });

    testWidgets('a mouse that drifts one pixel still reports', (tester) async {
      final reported = await pumpScrolling(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
        kind: PointerDeviceKind.mouse,
      );
      // kPrecisePointerHitSlop is 1.0: this is the drift that killed a real
      // mouse in this repo once, while every synthesised-tap test stayed green.
      await tester.pump(const Duration(milliseconds: 90));
      await gesture.moveBy(const Offset(1.5, 1.5));
      await tester.pump();
      await gesture.up();

      expect(reported.length, greaterThan(1));
    });

    testWidgets('pointer-down reports before any movement', (tester) async {
      final reported = await pumpScrolling(tester);
      final topLeft = tester.getTopLeft(find.byKey(key));

      final gesture = await tester.startGesture(topLeft + const Offset(75, 75));
      await tester.pump();

      expect(
        reported.single,
        const HSVColor.fromAHSV(1, 200, 0.25, 0.75),
        reason:
            'upstream jumps the colour to the click point from mousedown '
            '(useColorArea.ts, handleRootOnMouseDown)',
      );
      await gesture.up();
    });

    testWidgets('a drag off the edge clamps rather than asserting', (
      tester,
    ) async {
      final reported = await pumpScrolling(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await gesture.moveBy(const Offset(900, 900));
      await tester.pump();
      await gesture.up();

      expect(reported.last.saturation, 1);
      expect(reported.last.value, 0);
    });
  });

  group('pointer maths', () {
    testWidgets('saturation runs right to left under RTL, paint and all', (
      tester,
    ) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: reported.add,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
        direction: TextDirection.rtl,
      );

      expect(painterOf(tester).textDirection, TextDirection.rtl);
      await tester.tapAt(
        tester.getTopLeft(find.byKey(key)) + const Offset(75, 150),
      );
      await tester.pump();
      expect(
        reported.single.saturation,
        0.75,
        reason:
            'upstream mirrors the paint in RTL but not its hit-testing; this '
            'port mirrors both, so the thumb lands under the pointer',
      );
    });

    testWidgets('a zero-size box reports nothing', (tester) async {
      final reported = <HSVColor>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: SizedBox.shrink(
              child: FluentColorArea(
                key: key,
                color: teal,
                onChanged: reported.add,
                saturationLabel: 'Saturation',
                brightnessLabel: 'Brightness',
                style: FluentColorAreaStyle.from(minimumSize: Size.zero),
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(Offset.zero);
      await tester.pump();
      expect(
        reported,
        isEmpty,
        reason: 'upstream divides by the rect and turns the colour black',
      );
    });
  });

  group('keyboard', () {
    Future<List<HSVColor>> pumpFocused(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      final reported = <HSVColor>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: reported.add,
          focusNode: node,
          autofocus: true,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
        direction: direction,
      );
      await tester.pump();
      return reported;
    }

    testWidgets('arrows move one percent on the axis they name', (
      tester,
    ) async {
      final reported = await pumpFocused(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(reported.last.saturation, closeTo(0.51, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(reported.last.value, closeTo(0.51, 1e-9));
      expect(
        reported.last.hue,
        200,
        reason: 'the area edits exactly two channels',
      );
    });

    testWidgets('left increases under RTL, as the paint is mirrored', (
      tester,
    ) async {
      final reported = await pumpFocused(tester, direction: TextDirection.rtl);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(reported.last.saturation, closeTo(0.51, 1e-9));
    });

    testWidgets('repeated presses land exactly on the end and stop', (
      tester,
    ) async {
      var colour = const HSVColor.fromAHSV(1, 200, 0, 0.5);
      final reported = <HSVColor>[];
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) => FluentColorArea(
                  key: key,
                  color: colour,
                  onChanged: (next) {
                    reported.add(next);
                    setState(() => colour = next);
                  },
                  focusNode: node,
                  autofocus: true,
                  saturationLabel: 'Saturation',
                  brightnessLabel: 'Brightness',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 120; i += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }

      expect(colour.saturation, 1, reason: 'no floating-point drift past 1');
      expect(
        reported.length,
        100,
        reason:
            'the last 20 presses were no-ops, so nothing was reported — the '
            'quantise-then-compare in _report is what makes that true',
      );
    });
  });

  group('style resolution order', () {
    const override = FluentColorAreaStyle(
      borderColor: WidgetStatePropertyAll<Color?>(Color(0xFF00FF00)),
    );

    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorAreaTheme(
          style: FluentColorAreaStyle(
            borderColor: WidgetStatePropertyAll<Color?>(Color(0xFFFF0000)),
          ),
          child: FluentColorArea(
            key: key,
            color: teal,
            style: override,
            saturationLabel: 'Saturation',
            brightnessLabel: 'Brightness',
          ),
        ),
      );
      expect(painterOf(tester).borderColor, const Color(0xFF00FF00));
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      await pump(
        tester,
        const FluentColorAreaTheme(
          style: override,
          child: FluentColorArea(
            key: key,
            color: teal,
            saturationLabel: 'Saturation',
            brightnessLabel: 'Brightness',
          ),
        ),
      );
      expect(painterOf(tester).borderColor, const Color(0xFF00FF00));
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          style: override,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      final painter = painterOf(tester);
      expect(painter.borderColor, const Color(0xFF00FF00));
      expect(painter.thumbInnerColor, light().colors.neutralBackground1);
      expect(painter.borderRadius, FluentRadius.allMedium);
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentColorAreaBaseState(color: teal, enabled: true);
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentColorArea(
            base,
            FluentColorAreaStyle.from(
              borderColor: const Color(0xFF123456),
              minimumSize: const Size(300, 300),
              thumbSize: 22,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(painterOf(tester).borderColor, const Color(0xFF123456));
    });

    test('the style function can be reused and then adjusted', () {
      final resolved =
          resolveFluentColorAreaStyle(
            resolveFluentColorAreaState(color: teal),
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          ).merge(
            const FluentColorAreaStyle(
              borderWidth: WidgetStatePropertyAll<double?>(4),
            ),
          );
      expect(resolved.borderWidth!.resolve(const <WidgetState>{}), 4);
      expect(
        resolved.thumbInnerWidth!.resolve(const <WidgetState>{}),
        FluentStroke.thick,
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the paint', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralStroke1: magenta},
            child: Center(
              child: SizedBox(
                width: 300,
                child: FluentColorArea(
                  key: key,
                  color: teal,
                  saturationLabel: 'Saturation',
                  brightnessLabel: 'Brightness',
                ),
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).borderColor, magenta);
    });

    testWidgets('high contrast leaves nothing invisible', (tester) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final painter = painterOf(tester);
      expect(painter.borderColor!.a, 1.0, reason: 'square outline');
      expect(painter.thumbBorderColor!.a, 1.0, reason: 'thumb outline');
      expect(painter.thumbInnerColor!.a, 1.0, reason: 'thumb ring');
    });
  });

  group('motion', () {
    testWidgets('nothing animates, because upstream declares no transition', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ImplicitlyAnimatedWidget),
        ),
        findsNothing,
      );
    });
  });

  group('focus', () {
    testWidgets('a keyboard focus thickens the thumb border, in place', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: (_) {},
          focusNode: node,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      expect(painterOf(tester).thumbBorderWidth, FluentStroke.thin);

      // Keyboard-visible focus, not pointer focus: the thumb must not thicken
      // just because a click landed on the square.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      node.requestFocus();
      await tester.pump();

      final painter = painterOf(tester);
      expect(painter.thumbBorderWidth, FluentStroke.thick);
      expect(painter.thumbBorderColor, light().colors.strokeFocus2);
      expect(
        painter.thumbSize,
        24,
        reason:
            'a content-box 20 plus a 2px border. Upstream\'s translate(-50%, '
            '50%) cancels the thumb\'s own size, so the centre does not move.',
      );
    });
  });

  group('disabled is a real state, not a visual treatment', () {
    testWidgets('it ignores drags and keys but paints the same colours', (
      tester,
    ) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      final disabled = painterOf(tester);

      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: reported.add,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      final enabled = painterOf(tester);

      expect(
        disabled.thumbColor,
        enabled.thumbColor,
        reason:
            'upstream ships no disabled state for any part of the colour '
            'picker, and there are no tokens for one',
      );
      expect(disabled.borderColor, enabled.borderColor);

      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      await tester.tapAt(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(reported, isEmpty);
    });

    testWidgets('a disabled area lets the page scroll through it', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: const SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  child: FluentColorArea(
                    key: key,
                    color: teal,
                    saturationLabel: 'Saturation',
                    brightnessLabel: 'Brightness',
                  ),
                ),
                SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        greaterThan(0),
        reason:
            'a disabled control that kept its recogniser mounted would claim '
            'every pointer-down in its 300x300 rectangle and make the page '
            'unscrollable through it — silently',
      );
    });
  });

  group('accessibility', () {
    testWidgets('it announces two labelled axes and nothing else', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: (_) {},
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );

      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          children: <Matcher>[
            matchesSemantics(
              isSlider: true,
              hasEnabledState: true,
              isEnabled: true,
              label: 'Saturation',
              value: '50',
              increasedValue: '51',
              decreasedValue: '49',
              hasIncreaseAction: true,
              hasDecreaseAction: true,
            ),
            matchesSemantics(
              isSlider: true,
              hasEnabledState: true,
              isEnabled: true,
              label: 'Brightness',
              value: '50',
              increasedValue: '51',
              decreasedValue: '49',
              hasIncreaseAction: true,
              hasDecreaseAction: true,
            ),
          ],
        ),
        reason:
            'exactly two children: FluentInteractive would publish a third, '
            'spurious tap action without the ExcludeSemantics around it',
      );
      handle.dispose();
    });

    testWidgets('the increase and decrease actions move one axis each', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: reported.add,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );

      final saturation = tester.getSemantics(
        find.bySemanticsLabel('Saturation'),
      );
      final owner = saturation.owner!;
      owner.performAction(saturation.id, SemanticsAction.increase);
      await tester.pump();
      expect(reported.last.saturation, closeTo(0.51, 1e-9));

      final brightness = tester.getSemantics(
        find.bySemanticsLabel('Brightness'),
      );
      owner.performAction(brightness.id, SemanticsAction.decrease);
      await tester.pump();
      expect(reported.last.value, closeTo(0.49, 1e-9));
      handle.dispose();
    });

    testWidgets('a formatter sees the whole colour, not one axis', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorArea(
          key: key,
          color: teal,
          onChanged: (_) {},
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
          // Upstream's own stories announce both channels from either axis:
          // `Saturation 50, Brightness: 50, teal`.
          semanticFormatter: (colour, axis) =>
              'S${(colour.saturation * 100).round()} '
              'B${(colour.value * 100).round()}',
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Saturation')).value,
        'S50 B50',
      );
      handle.dispose();
    });

    testWidgets('a disabled area announces disabled, not just grey', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentColorArea(
          key: key,
          color: teal,
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Saturation')),
        matchesSemantics(
          isSlider: true,
          hasEnabledState: true,
          label: 'Saturation',
          value: '50',
          increasedValue: '51',
          decreasedValue: '49',
        ),
        reason:
            'no increase or decrease action and no focusability: disabled is a '
            'real state change here, not a repaint',
      );
      handle.dispose();
    });
  });

  group('the colour model', () {
    test('a grey colour keeps its hue', () {
      const grey = HSVColor.fromAHSV(1, 210, 0, 1);
      const state = FluentColorAreaBaseState(color: grey, enabled: true);
      expect(
        state.hueColor,
        const Color(0xFF0080FF),
        reason:
            'the hue comes from the model. Deriving it from a Color — which is '
            'what upstream does through tinycolor — collapses grey to hue 0 '
            'and turns the square red.',
      );
      expect(state.colorAt(0.5, 0.5).hue, 210);
    });

    test('a coordinate off the square is a colour on its edge', () {
      const state = FluentColorAreaBaseState(color: teal, enabled: true);
      expect(state.colorAt(4, -2).saturation, 1);
      expect(state.colorAt(4, -2).value, 0);
    });

    test('colours quantise to whole percent, so == is usable', () {
      const state = FluentColorAreaBaseState(color: teal, enabled: true);
      expect(state.colorAt(0.5049, 0.5).saturation, 0.5);
      expect(state.colorAt(0.5051, 0.5).saturation, 0.51);
    });
  });
}
