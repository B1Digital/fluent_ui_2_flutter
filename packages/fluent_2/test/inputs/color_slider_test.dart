import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentColorSlider` paints its rail and thumb rather than composing them, so
/// every assertion reads `FluentColorSliderPainter`'s public fields — which is
/// exactly why they are public.
///
/// There is no Figma fixture: ColorPicker is preview-tier upstream
/// (`@fluentui/react-color-picker-preview`) and publishes no component set, so
/// the oracle is `useColorSliderStyles.styles.ts` and `useColorSlider.ts`
/// themselves. Every assertion names the rule it comes from.
void main() {
  const key = Key('rail');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget rail, {
    FluentThemeData? theme,
    double? width = 300,
    double? height,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      home: Directionality(
        textDirection: direction,
        child: Center(
          // Only the axis under test is constrained. Tightening the other one
          // would force the control off its own minimum, which is what a
          // caller must not have to think about.
          child: SizedBox(width: width, height: height, child: rail),
        ),
      ),
    ),
  );

  FluentColorSliderPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentColorSliderPainter>()
      .first;

  const teal = HSVColor.fromAHSV(1, 200, 0.5, 0.5);

  group('geometry, every shape, against upstream\'s styles file', () {
    testWidgets('a horizontal rail is 200 x 32 at minimum, rail 20 deep', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
        width: 260,
      );
      final box = tester.getSize(
        find
            .descendant(of: find.byKey(key), matching: find.byType(CustomPaint))
            .first,
      );
      expect(box.height, 32, reason: 'min-height: 32px in the reset styles');
      expect(box.width, 260, reason: 'the centre grid track is 100%');

      final painter = painterOf(tester);
      expect(painter.railThickness, 20, reason: '--fui-Slider__rail--size');
      // A 3x3 grid with 1fr above and below a 20 track inside 32.
      expect(painter.railRect(box), const Rect.fromLTWH(0, 6, 260, 20));
    });

    testWidgets('a vertical rail is 20 x 280 at minimum', (tester) async {
      await pump(
        tester,
        const FluentColorSlider(
          key: key,
          color: teal,
          vertical: true,
          semanticLabel: 'Hue',
        ),
        width: null,
        height: 320,
      );
      final box = tester.getSize(
        find
            .descendant(of: find.byKey(key), matching: find.byType(CustomPaint))
            .first,
      );
      expect(box.width, 20, reason: 'the cross track is the thumb size');
      expect(box.height, 320);
      expect(
        painterOf(tester).railRect(box),
        const Rect.fromLTWH(0, 0, 20, 320),
      );
    });

    testWidgets('rounded is borderRadiusMedium and square is none', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      expect(painterOf(tester).railRadius, FluentRadius.allMedium);

      await pump(
        tester,
        const FluentColorSlider(
          key: key,
          color: teal,
          shape: FluentColorPickerShape.square,
          semanticLabel: 'Hue',
        ),
      );
      expect(painterOf(tester).railRadius, BorderRadius.zero);
    });

    testWidgets('a colour rail outlines in colorTransparentStroke', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      final painter = painterOf(tester);
      expect(painter.railBorderWidth, FluentStroke.thin);
      expect(
        painter.railBorderColor,
        light().colors.transparentStroke,
        reason:
            'invisible on an ordinary surface, a real edge under forced '
            'colours — which is why it is a token and not a transparent '
            'literal',
      );
    });

    testWidgets('the thumb is a 22 disc, as on the colour area', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      final painter = painterOf(tester);
      final colors = light().colors;
      expect(painter.thumbSize, 22);
      expect(painter.thumbBorderWidth, FluentStroke.thin);
      expect(painter.thumbBorderColor, colors.neutralForeground4);
      expect(painter.thumbInnerWidth, FluentStroke.thick);
      expect(painter.thumbInnerColor, colors.neutralBackground1);
      expect(painter.thumbShadow, light().shadow(FluentElevation.shadow4));
    });
  });

  group('channels', () {
    test('the hue ramp is seven ascending stops, red through red', () {
      expect(FluentColorSliderPainter.hueRamp, const <Color>[
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ]);
      // Upstream writes the same stops descending and reverses them with a
      // -90deg angle; ascending plus an anchor covers RTL and vertical too.
      expect(
        FluentColorSliderPainter.hueRamp[1],
        const HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
        reason: 'the stop at one sixth is hue 60',
      );
    });

    test('saturation and value ramp from grey and black to the pure hue', () {
      const state = FluentColorSliderBaseState(
        color: teal,
        channel: FluentColorChannel.saturation,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      expect(state.railColors.first, const Color(0xFF808080));
      expect(
        state.railColors.last,
        const HSVColor.fromAHSV(1, 200, 1, 1).toColor(),
      );

      const value = FluentColorSliderBaseState(
        color: teal,
        channel: FluentColorChannel.value,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      expect(value.railColors.first, const Color(0xFF000000));
      expect(
        value.railColors.last,
        const HSVColor.fromAHSV(1, 200, 1, 1).toColor(),
      );
    });

    test('a saturation rail at s = 0 keeps its own hue', () {
      const grey = HSVColor.fromAHSV(1, 200, 0, 1);
      const state = FluentColorSliderBaseState(
        color: grey,
        channel: FluentColorChannel.saturation,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      expect(
        state.railColors.last,
        const Color(0xFF00AAFF),
        reason:
            'upstream derives the rail colour through tinycolor(hsv).toHsl(), '
            'so picking white turns its saturation and value rails red. The '
            'hue here comes from the model and survives.',
      );
    });

    test('each channel reports its own maximum and value', () {
      FluentColorSliderBaseState of(FluentColorChannel channel) =>
          FluentColorSliderBaseState(
            color: teal,
            channel: channel,
            vertical: false,
            transparency: false,
            enabled: true,
          );
      expect(of(FluentColorChannel.hue).maximum, 360);
      expect(of(FluentColorChannel.hue).channelValue, 200);
      expect(of(FluentColorChannel.saturation).maximum, 100);
      expect(of(FluentColorChannel.saturation).channelValue, 50);
      expect(of(FluentColorChannel.value).channelValue, 50);
      expect(of(FluentColorChannel.alpha).channelValue, 100);
    });

    test('a channel edits itself and nothing else', () {
      const state = FluentColorSliderBaseState(
        color: teal,
        channel: FluentColorChannel.hue,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      final next = state.colorAt(300);
      expect(next.hue, 300);
      expect(next.saturation, teal.saturation);
      expect(next.value, teal.value);
      expect(next.alpha, teal.alpha);
    });

    test('hue 360 is reachable, and is not wrapped to 0', () {
      const state = FluentColorSliderBaseState(
        color: teal,
        channel: FluentColorChannel.hue,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      expect(
        state.colorAt(360).hue,
        360,
        reason:
            'clamped, never `% 360`: wrapping would put the maximum of the '
            'rail permanently out of reach',
      );
      expect(
        state.colorAt(361).hue,
        360,
        reason: 'HSVColor.fromAHSV asserts hue <= 360',
      );
      expect(state.colorAt(-4).hue, 0);
    });
  });

  group('orientation and direction', () {
    testWidgets('the anchor is start, mirrored under RTL, bottom if vertical', (
      tester,
    ) async {
      expect(
        fluentColorRailAnchor(
          vertical: false,
          textDirection: TextDirection.ltr,
        ),
        Alignment.centerLeft,
      );
      expect(
        fluentColorRailAnchor(
          vertical: false,
          textDirection: TextDirection.rtl,
        ),
        Alignment.centerRight,
      );
      expect(
        fluentColorRailAnchor(vertical: true, textDirection: TextDirection.rtl),
        Alignment.bottomCenter,
        reason:
            'a vertical rail is never mirrored — its minimum is at the bottom '
            'in both reading directions',
      );
    });

    testWidgets('the thumb sits on the anchor edge at zero, with no inset', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(
          key: key,
          color: HSVColor.fromAHSV(1, 0, 1, 1),
          semanticLabel: 'Hue',
        ),
        width: 200,
      );
      final painter = painterOf(tester);
      expect(
        painter.thumbCentre(const Size(200, 32)).dx,
        0,
        reason:
            'upstream\'s 1fr 100% 1fr grid collapses the outer tracks, so the '
            'thumb hangs half its width past the end and hue 0 lands on the '
            'first pixel of the gradient',
      );
    });

    testWidgets('a vertical rail puts its minimum at the bottom', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(
          key: key,
          color: HSVColor.fromAHSV(1, 0, 1, 1),
          vertical: true,
          semanticLabel: 'Hue',
        ),
        width: null,
        height: 280,
      );
      expect(painterOf(tester).thumbCentre(const Size(20, 280)).dy, 280);
    });
  });

  group('pointer input', () {
    testWidgets('a press anywhere reports the value under it', (tester) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: reported.add,
          semanticLabel: 'Hue',
        ),
        width: 360,
      );
      final rail = tester.getRect(find.byKey(key));
      await tester.tapAt(Offset(rail.left + 180, rail.center.dy));
      await tester.pump();
      expect(reported.single.hue, 180);
    });

    testWidgets('the rail runs right to left under RTL', (tester) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: reported.add,
          semanticLabel: 'Hue',
        ),
        width: 360,
        direction: TextDirection.rtl,
      );
      final rail = tester.getRect(find.byKey(key));
      await tester.tapAt(Offset(rail.left + 180, rail.center.dy));
      await tester.pump();
      expect(reported.single.hue, 180);

      await tester.tapAt(Offset(rail.left + 1, rail.center.dy));
      await tester.pump();
      expect(reported.last.hue, 359, reason: 'the maximum is on the left');
    });

    testWidgets('a vertical drag inside a scroll view does not scroll it', (
      tester,
    ) async {
      final reported = <HSVColor>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 200,
                  height: 280,
                  child: FluentColorSlider(
                    key: key,
                    color: teal,
                    vertical: true,
                    onChanged: reported.add,
                    semanticLabel: 'Hue',
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
      );
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
        reason: 'a vertical rail and a vertical viewport share an axis',
      );
    });

    testWidgets('a mouse that drifts one pixel still reports', (tester) async {
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: reported.add,
          semanticLabel: 'Hue',
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(key)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 90));
      await gesture.moveBy(const Offset(1.5, 0));
      await tester.pump();
      await gesture.up();
      expect(reported.length, greaterThan(1));
    });

    testWidgets('a zero-width rail reports nothing', (tester) async {
      final reported = <HSVColor>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: SizedBox.shrink(
              child: FluentColorSlider(
                key: key,
                color: teal,
                onChanged: reported.add,
                semanticLabel: 'Hue',
                style: FluentColorSliderStyle.from(minimumSize: Size.zero),
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(Offset.zero);
      await tester.pump();
      expect(reported, isEmpty);
    });
  });

  group('keyboard', () {
    Future<List<HSVColor>> pumpFocused(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool vertical = false,
    }) async {
      final reported = <HSVColor>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          vertical: vertical,
          onChanged: reported.add,
          focusNode: node,
          autofocus: true,
          semanticLabel: 'Hue',
        ),
        direction: direction,
      );
      await tester.pump();
      return reported;
    }

    testWidgets('arrows move one unit and Home/End jump to the ends', (
      tester,
    ) async {
      final reported = await pumpFocused(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(reported.last.hue, 201);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(reported.last.hue, 199);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(reported.last.hue, 360);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(reported.last.hue, 0);
    });

    testWidgets('left increases under RTL, because the rail is mirrored', (
      tester,
    ) async {
      final reported = await pumpFocused(tester, direction: TextDirection.rtl);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(reported.last.hue, 201);
    });

    testWidgets('a vertical rail is not mirrored under RTL', (tester) async {
      final reported = await pumpFocused(
        tester,
        direction: TextDirection.rtl,
        vertical: true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(reported.last.hue, 201);
    });
  });

  group('style resolution order', () {
    const override = FluentColorSliderStyle(
      railBorderColor: WidgetStatePropertyAll<Color?>(Color(0xFF00FF00)),
    );

    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSliderTheme(
          style: FluentColorSliderStyle(
            railBorderColor: WidgetStatePropertyAll<Color?>(Color(0xFFFF0000)),
          ),
          child: FluentColorSlider(
            key: key,
            color: teal,
            style: override,
            semanticLabel: 'Hue',
          ),
        ),
      );
      expect(painterOf(tester).railBorderColor, const Color(0xFF00FF00));
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      await pump(
        tester,
        const FluentColorSliderTheme(
          style: override,
          child: FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
        ),
      );
      expect(painterOf(tester).railBorderColor, const Color(0xFF00FF00));
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(
          key: key,
          color: teal,
          style: override,
          semanticLabel: 'Hue',
        ),
      );
      final painter = painterOf(tester);
      expect(painter.railBorderColor, const Color(0xFF00FF00));
      expect(painter.railThickness, 20);
      expect(painter.thumbInnerColor, light().colors.neutralBackground1);
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentColorSliderBaseState(
        color: teal,
        channel: FluentColorChannel.hue,
        vertical: false,
        transparency: false,
        enabled: true,
      );
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentColorSlider(
            base,
            FluentColorSliderStyle.from(
              railBorderColor: const Color(0xFF123456),
              railThickness: 20,
              minimumSize: const Size(200, 32),
              thumbSize: 22,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(painterOf(tester).railBorderColor, const Color(0xFF123456));
    });

    test('the style function can be reused and then adjusted', () {
      final resolved =
          resolveFluentColorSliderStyle(
            resolveFluentColorSliderState(color: teal),
            light(),
          ).merge(
            const FluentColorSliderStyle(
              railThickness: WidgetStatePropertyAll<double?>(4),
            ),
          );
      expect(resolved.railThickness!.resolve(const <WidgetState>{}), 4);
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
            colors: {FluentColorToken.neutralBackground1: magenta},
            child: Center(
              child: SizedBox(
                width: 300,
                child: FluentColorSlider(
                  key: key,
                  color: teal,
                  semanticLabel: 'Hue',
                ),
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).thumbInnerColor, magenta);
    });

    testWidgets('high contrast leaves the thumb readable', (tester) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final painter = painterOf(tester);
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
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
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
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: (_) {},
          focusNode: node,
          semanticLabel: 'Hue',
        ),
      );
      expect(painterOf(tester).thumbBorderWidth, FluentStroke.thin);

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
        reason: 'upstream\'s input:focus-visible ~ .thumb rule, 1px -> 2px',
      );
      expect(
        painter.thumbCentre(const Size(300, 32)).dx,
        painterOf(tester).thumbCentre(const Size(300, 32)).dx,
        reason: 'the centre does not move when the thumb grows',
      );
    });
  });

  group('disabled is a real state, not a visual treatment', () {
    testWidgets('it ignores presses and keys but paints the same colours', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      final disabled = painterOf(tester);

      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: reported.add,
          semanticLabel: 'Hue',
        ),
      );
      final enabled = painterOf(tester);
      expect(disabled.thumbColor, enabled.thumbColor);
      expect(disabled.railBorderColor, enabled.railBorderColor);

      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      await tester.tapAt(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(reported, isEmpty);
    });
  });

  group('accessibility', () {
    testWidgets('it announces itself as a slider with a value', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: (_) {},
          semanticLabel: 'Hue',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Hue',
          value: '200',
          increasedValue: '201',
          decreasedValue: '199',
          isFocusable: true,
          hasFocusAction: true,
          // FluentInteractive publishes a tap action to mark the control
          // enabled. Harmless on a rail — every Fluent slider carries it — and
          // deliberately excluded on the colour area, where it would have made
          // a spurious third child beside the two axes.
          hasTapAction: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the increase and decrease actions move the value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final reported = <HSVColor>[];
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: reported.add,
          semanticLabel: 'Hue',
        ),
      );
      final node = tester.getSemantics(find.byKey(key));
      final owner = node.owner!;
      owner.performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      expect(reported.last.hue, 201);
      owner.performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(reported.last.hue, 199);
      handle.dispose();
    });

    testWidgets('a formatter names the unit', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorSlider(
          key: key,
          color: teal,
          onChanged: (_) {},
          semanticLabel: 'Hue',
          semanticFormatter: (value) => '${value.round()} degrees',
        ),
      );
      expect(tester.getSemantics(find.byKey(key)).value, '200 degrees');
      handle.dispose();
    });

    testWidgets('a disabled rail announces disabled, not just grey', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentColorSlider(key: key, color: teal, semanticLabel: 'Hue'),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          isSlider: true,
          hasEnabledState: true,
          label: 'Hue',
          value: '200',
          increasedValue: '201',
          decreasedValue: '199',
        ),
        reason:
            'no increase or decrease action, no tap and no focusability: '
            'disabled is a real state change, not a repaint',
      );
      handle.dispose();
    });
  });
}
