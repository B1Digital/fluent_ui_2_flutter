import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentDrawer` is the package's first *modal* overlay, so these tests carry
/// three things the tooltip and dropdown ones do not: a size-keyed transition
/// that has to be exactly as long as upstream says, a focus trap that has to
/// return focus where it found it, and a scrim that has to stay opaque in high
/// contrast.
void main() {
  const body = Key('body');
  const outside = Key('outside');

  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// Every drawer test uses the default 800x600 surface, so a `small` drawer
  /// anchored to the trailing edge starts at x = 800 - 320.
  const double surfaceWidth = 800;

  Widget app(
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    TextDirection? direction,
  }) => FluentApp(
    theme: theme ?? light,
    builder: reducedMotion
        ? (context, inner) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: inner!,
          )
        : null,
    home: direction == null
        ? child
        : Directionality(textDirection: direction, child: child),
  );

  /// The panel's own decorated surface, found through the body rather than
  /// through the widget — an overlay drawer's panel lives in the `Overlay`,
  /// not under `FluentDrawer`.
  Finder panelOf() =>
      find.ancestor(of: find.byKey(body), matching: find.byType(DecoratedBox));

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(panelOf())
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  Iterable<Color> colouredBoxes(WidgetTester tester) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .map((b) => b.color);

  FluentDrawerStyle styleFor({
    FluentDrawerType type = FluentDrawerType.overlay,
    FluentDrawerSize size = FluentDrawerSize.small,
    FluentDrawerPosition position = FluentDrawerPosition.start,
    bool separator = false,
    FluentThemeData? theme,
  }) => resolveFluentDrawerStyle(
    resolveFluentDrawerState(
      open: true,
      type: type,
      size: size,
      position: position,
      separator: separator,
      child: const SizedBox.shrink(),
    ),
    theme ?? light,
  );

  T resolved<T>(WidgetStateProperty<T>? property) =>
      property!.resolve(const <WidgetState>{});

  group('pixel fidelity against Figma', () {
    final overlaySpec = loadSpec('overlay_drawer');
    final inlineSpec = loadSpec('inline_drawer');

    test('the fixtures cover both component sets whole', () {
      expect(overlaySpec.variants.length, 3);
      expect(overlaySpec.properties['Size'], ['Small', 'Medium', 'Large']);
      expect(inlineSpec.variants.length, 9);
      expect(inlineSpec.properties['Size'], ['Small', 'Medium', 'Large']);
      expect(inlineSpec.properties['Vertical Divider'], [
        'None',
        'Left',
        'Right',
      ]);
      // Neither set has a State axis. That is the whole reason every token in
      // resolveFluentDrawerStyle is a single-token set rather than a ramp.
      expect(overlaySpec.properties.keys, ['Size']);
      expect(inlineSpec.properties.keys, ['Size', 'Vertical Divider']);
    });

    test('every size resolves to the Figma width, on both types', () {
      const names = {
        FluentDrawerSize.small: 'Small',
        FluentDrawerSize.medium: 'Medium',
        FluentDrawerSize.large: 'Large',
      };
      for (final entry in names.entries) {
        final overlay = overlaySpec.variant({'Size': entry.value});
        expect(
          resolved(styleFor(size: entry.key).width),
          overlay.size.width,
          reason: '${entry.value}: overlay width',
        );
        final inline = inlineSpec.variant({
          'Size': entry.value,
          'Vertical Divider': 'None',
        });
        expect(
          resolved(
            styleFor(type: FluentDrawerType.inline, size: entry.key).width,
          ),
          inline.size.width,
          reason: '${entry.value}: inline width',
        );
      }
      // `full` has no Figma variant — it is upstream's 100vw, expressed as
      // "whatever the parent allows".
      expect(
        resolved(styleFor(size: FluentDrawerSize.full).width),
        double.infinity,
      );
    });

    test('the panel fill is the Figma token in both types', () {
      // Figma paints Neutral/Background/1/Rest on the inline variant frame and
      // on each of the overlay drawer's three slots; either way the panel is
      // that token.
      final inline = inlineSpec.variant({
        'Size': 'Small',
        'Vertical Divider': 'None',
      });
      expect(inline.token('fills'), 'Neutral/Background/1/Rest');
      expect(
        resolved(styleFor(type: FluentDrawerType.inline).backgroundColor),
        inline.fill,
      );

      final overlay = overlaySpec.variant({'Size': 'Small'});
      final header = overlay.part('Header');
      expect(header.token('fills'), 'Neutral/Background/1/Rest');
      expect(resolved(styleFor().backgroundColor), header.fill);
    });

    test('the header, body and footer insets are the Figma frames', () {
      final variant = overlaySpec.variant({'Size': 'Small'});
      final style = styleFor();

      final header = variant.part('Navigation base');
      expect(header.token('paddingTop'), 'Spacing/Vertical/XXL');
      expect(header.token('paddingLeft'), 'Spacing/Horizontal/XXL');
      // Not XXL: Figma folds React's -spacingHorizontalS action margin into
      // the frame, so the end inset is L.
      expect(header.token('paddingRight'), 'Spacing/Horizontal/L');
      expect(header.token('paddingBottom'), 'Spacing/Vertical/M');
      expect(
        resolved(style.headerPadding)!.resolve(TextDirection.ltr),
        header.padding,
      );
      expect(resolved(style.headerGap), header.gap);
      expect(header.token('itemSpacing'), 'Spacing/Horizontal/S');

      final bodyPart = variant.part('Body');
      expect(bodyPart.token('paddingLeft'), 'Spacing/Horizontal/XXL');
      expect(
        resolved(style.bodyPadding)!.resolve(TextDirection.ltr),
        bodyPart.padding,
      );

      final footer = variant.part('Footer');
      expect(footer.token('paddingTop'), 'Spacing/Vertical/L');
      expect(footer.token('paddingBottom'), 'Spacing/Vertical/XXL');
      expect(
        resolved(style.footerPadding)!.resolve(TextDirection.ltr),
        footer.padding,
      );
      expect(resolved(style.footerGap), variant.part('Button container').gap);
    });

    test('the header follows the published Web subtitle metric', () {
      final text = overlaySpec.variant({'Size': 'Small'}).text!;
      expect(text.tokens['fontSize'], ['Typography/Font size/500']);
      expect(text.tokens['lineHeight'], ['Typography/Line height/500']);
      expect(text.fontStyle, 'Semibold');

      final style = resolved(styleFor().headerTextStyle)!;
      expect(style.fontSize, text.fontSize);
      // The Community Figma token still resolves to 28. The current Fluent 2
      // platform table specifies 20/26 for Web, which the platform ramp uses.
      expect(text.lineHeight, 28);
      expect(style.height! * style.fontSize!, 26);
    });

    test('the inline rule is the Figma rule, and only when asked for', () {
      // Figma models the side as a Left/Right axis; React derives it from
      // position. Both agree on the tone and the width.
      for (final side in ['Left', 'Right']) {
        final variant = inlineSpec.variant({
          'Size': 'Small',
          'Vertical Divider': side,
        });
        final rule = variant.part('Line 1');
        expect(rule.token('strokes'), 'Neutral/Stroke/2/Rest');
        expect(rule.token('strokeWeight'), 'Stroke width/Thin');
        final style = styleFor(type: FluentDrawerType.inline, separator: true);
        expect(resolved(style.borderColor), rule.stroke, reason: side);
        expect(resolved(style.borderWidth), rule.strokeWidth, reason: side);
      }

      // Vertical Divider=None has no rule layer at all in Figma. We still draw
      // one, in `transparentStroke`, because `useDrawerBaseStyles` gives inline
      // and overlay alike a `strokeWidthThin solid colorTransparentStroke` edge
      // (live probe components-drawer--inline: `borderWidth: 0px 1px 0px 0px`,
      // `borderColor: rgba(0, 0, 0, 0)`) — invisible in light and dark, opaque
      // in high contrast, and 1px of real layout width either way.
      final none = inlineSpec.variant({
        'Size': 'Small',
        'Vertical Divider': 'None',
      });
      expect(() => none.part('Line 1'), throwsStateError);
      final bare = styleFor(type: FluentDrawerType.inline);
      expect(resolved(bare.borderColor), light.colors.transparentStroke);
      expect(resolved(bare.borderWidth), FluentStroke.thin);
    });

    test('only the overlay drawer is elevated, and it is shadow64', () {
      // Figma binds one effect style on all three overlay variants — ambient
      // (0,0) blur 8, key (0,32) blur 64 — and nothing on the nine inline ones.
      final shadows = resolved(styleFor().shadow)!;
      expect(shadows, light.shadow(FluentElevation.shadow64));
      expect(shadows[0].blurRadius, 8);
      expect(shadows[1].offset, const Offset(0, 32));
      expect(shadows[1].blurRadius, 64);
      expect(resolved(styleFor(type: FluentDrawerType.inline).shadow), isNull);
    });

    testWidgets('the resolved insets actually land on the panel', (
      tester,
    ) async {
      final variant = loadSpec('overlay_drawer').variant({'Size': 'Small'});
      await tester.pumpWidget(
        app(
          const FluentDrawer(
            open: true,
            header: <Widget>[Text('Title')],
            footer: <Widget>[Text('Save')],
            child: SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(panelOf().first).width, variant.size.width);
      // The body sits inset by the Figma XXL on both sides.
      expect(
        tester.getTopLeft(find.byKey(body)).dx,
        variant.part('Body').padding!.left,
      );
    });
  });

  group('motion', () {
    test('the durations are upstream\'s, keyed off size', () {
      const expected = {
        FluentDrawerSize.small: FluentDuration.gentle,
        FluentDrawerSize.medium: FluentDuration.slow,
        FluentDrawerSize.large: FluentDuration.slower,
        FluentDrawerSize.full: FluentDuration.ultraSlow,
      };
      expected.forEach((size, duration) {
        expect(fluentDrawerDuration(size), duration, reason: size.name);
        expect(fluentDrawerEnter(size).duration, duration);
        expect(fluentDrawerExit(size).duration, duration);
        expect(fluentDrawerScrimFade(size).duration, duration);
      });
      expect(fluentDrawerDuration(FluentDrawerSize.small).inMilliseconds, 250);
      expect(fluentDrawerDuration(FluentDrawerSize.medium).inMilliseconds, 300);
      expect(fluentDrawerDuration(FluentDrawerSize.large).inMilliseconds, 400);
      expect(fluentDrawerDuration(FluentDrawerSize.full).inMilliseconds, 500);
    });

    test('the curves are decelerate in, accelerate out, linear scrim', () {
      for (final size in FluentDrawerSize.values) {
        expect(fluentDrawerEnter(size).curve, FluentCurve.decelerateMid);
        expect(fluentDrawerExit(size).curve, FluentCurve.accelerateMin);
        expect(fluentDrawerScrimFade(size).curve, FluentCurve.linear);
      }
    });

    testWidgets('the entrance runs for exactly the size\'s duration', (
      tester,
    ) async {
      for (final size in <FluentDrawerSize>[
        FluentDrawerSize.small,
        FluentDrawerSize.medium,
        FluentDrawerSize.large,
      ]) {
        await tester.pumpWidget(
          app(
            FluentDrawer(
              size: size,
              child: const SizedBox.expand(key: body),
            ),
          ),
        );
        await tester.pumpWidget(
          app(
            FluentDrawer(
              open: true,
              size: size,
              child: const SizedBox.expand(key: body),
            ),
          ),
        );
        // The entry is inserted post-frame, so the transition starts here.
        await tester.pump();
        await tester.pump();

        final duration = fluentDrawerDuration(size);
        await tester.pump(duration - const Duration(milliseconds: 1));
        expect(
          tester.binding.transientCallbackCount,
          greaterThan(0),
          reason: '${size.name}: still animating one millisecond short',
        );
        await tester.pump(const Duration(milliseconds: 2));
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason:
              '${size.name}: settled at exactly ${duration.inMilliseconds}ms',
        );
        expect(tester.getTopLeft(panelOf().first).dx, 0);

        await tester.pumpWidget(app(const SizedBox.shrink()));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the panel slides in from its own edge', (tester) async {
      await tester.pumpWidget(
        app(const FluentDrawer(child: SizedBox.expand(key: body))),
      );
      await tester.pumpWidget(
        app(const FluentDrawer(open: true, child: SizedBox.expand(key: body))),
      );
      await tester.pump();
      await tester.pump();

      // One frame in, the panel is still mostly off the leading edge.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getTopLeft(panelOf().first).dx, lessThan(0));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panelOf().first).dx, 0);
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const FluentDrawer(child: SizedBox.expand(key: body)),
          reducedMotion: true,
        ),
      );
      await tester.pumpWidget(
        app(
          const FluentDrawer(open: true, child: SizedBox.expand(key: body)),
          reducedMotion: true,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.getTopLeft(panelOf().first).dx,
        0,
        reason: 'fully open, not mid-slide',
      );
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'no ticker may be running at all',
      );
      expect(
        colouredBoxes(tester),
        contains(light.colors.backgroundOverlay),
        reason: 'the scrim is at full strength too',
      );

      // ...and closing is just as instant.
      await tester.pumpWidget(
        app(
          const FluentDrawer(child: SizedBox.expand(key: body)),
          reducedMotion: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(body), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('theming', () {
    testWidgets('a subtree override reaches the panel in the overlay', (
      tester,
    ) async {
      // The panel builds inside the Overlay, outside FluentDrawer's own
      // subtree, so this only passes because FluentTheme is an InheritedTheme
      // and the style is resolved against the trigger's context.
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        app(
          const FluentThemeOverride(
            colors: {FluentColorToken.neutralBackground1: magenta},
            child: FluentDrawer(open: true, child: SizedBox.expand(key: body)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('a FluentDrawerTheme reaches the overlay too', (tester) async {
      const themed = Color(0xFF112233);
      await tester.pumpWidget(
        app(
          FluentDrawerTheme(
            style: FluentDrawerStyle.from(backgroundColor: themed),
            child: const FluentDrawer(
              open: true,
              child: SizedBox.expand(key: body),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('high contrast keeps the rule and the scrim visible', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await tester.pumpWidget(
        app(
          const FluentDrawer(open: true, child: SizedBox.expand(key: body)),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      // transparentStroke resolves to canvasText in high contrast, so the rule
      // that is invisible in light mode has to read here. A hardcoded
      // Colors.transparent would silently stay invisible.
      final border = decorationOf(tester).border! as BorderDirectional;
      expect(border.end.color.a, 1.0);
      expect(border.end.width, greaterThan(0));

      // And the scrim is a real token, not Colors.transparent.
      expect(theme.colors.backgroundOverlay.a, greaterThan(0));
      expect(colouredBoxes(tester), contains(theme.colors.backgroundOverlay));
    });

    testWidgets('high contrast outlines an inline drawer with no separator', (
      tester,
    ) async {
      // Regression: the unseparated inline drawer used to resolve borderWidth
      // to `none`, so `buildFluentDrawer` built no BorderDirectional at all and
      // the panel had no edge in high contrast — where transparentStroke is the
      // only thing that would have drawn one. React keeps the transparent edge
      // on every drawer (`useDrawerBaseStyles`), which is why it does not.
      await tester.pumpWidget(
        app(
          const Row(
            children: <Widget>[
              FluentDrawer(
                type: FluentDrawerType.inline,
                open: true,
                child: SizedBox.expand(key: body),
              ),
            ],
          ),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final border = decorationOf(tester).border! as BorderDirectional;
      expect(border.end.width, FluentStroke.thin);
      expect(border.end.color.a, 1.0);
    });

    testWidgets('every theme paints an opaque-enough scrim', (tester) async {
      for (final theme in <FluentThemeData>[
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
        FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
      ]) {
        expect(
          theme.colors.backgroundOverlay.a,
          greaterThanOrEqualTo(0.4),
          reason: '${theme.brightness} scrim alpha',
        );
      }
    });
  });

  group('placement', () {
    testWidgets('start and end anchor to opposite edges', (tester) async {
      await tester.pumpWidget(
        app(const FluentDrawer(open: true, child: SizedBox.expand(key: body))),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(panelOf().first).dx, 0);

      await tester.pumpWidget(
        app(
          const FluentDrawer(
            open: true,
            position: FluentDrawerPosition.end,
            child: SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(panelOf().first).dx,
        surfaceWidth - fluentDrawerSmallWidth,
      );
    });

    testWidgets('RTL flips the anchor and the slide', (tester) async {
      await tester.pumpWidget(
        app(
          const FluentDrawer(child: SizedBox.expand(key: body)),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpWidget(
        app(
          const FluentDrawer(open: true, child: SizedBox.expand(key: body)),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      await tester.pump();

      // Offscreen is to the RIGHT in RTL, so the panel starts beyond the
      // trailing edge and settles against it.
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.getTopLeft(panelOf().first).dx,
        greaterThan(surfaceWidth - fluentDrawerSmallWidth),
      );

      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(panelOf().first).dx,
        surfaceWidth - fluentDrawerSmallWidth,
      );
    });

    testWidgets('the rule sits on the edge facing the page', (tester) async {
      await tester.pumpWidget(
        app(const FluentDrawer(open: true, child: SizedBox.expand(key: body))),
      );
      await tester.pumpAndSettle();
      var border = decorationOf(tester).border! as BorderDirectional;
      expect(border.end.width, FluentStroke.thin);
      expect(border.start, BorderSide.none);

      await tester.pumpWidget(
        app(
          const FluentDrawer(
            open: true,
            position: FluentDrawerPosition.end,
            child: SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();
      border = decorationOf(tester).border! as BorderDirectional;
      expect(border.start.width, FluentStroke.thin);
      expect(border.end, BorderSide.none);
    });

    testWidgets('an inline drawer builds in place and takes width', (
      tester,
    ) async {
      Widget row({required bool open}) => app(
        Row(
          children: <Widget>[
            FluentDrawer(
              type: FluentDrawerType.inline,
              open: open,
              child: const SizedBox.expand(key: body),
            ),
            const Expanded(child: SizedBox.expand(key: outside)),
          ],
        ),
      );

      await tester.pumpWidget(row(open: false));
      await tester.pumpAndSettle();
      expect(find.byKey(body), findsNothing);
      expect(tester.getSize(find.byKey(outside)).width, surfaceWidth);

      await tester.pumpWidget(row(open: true));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(outside)).width, 480);
      expect(
        colouredBoxes(tester),
        isNot(contains(light.colors.backgroundOverlay)),
        reason: 'an inline drawer is not modal and paints no scrim',
      );
    });
  });

  group('open is the real state', () {
    // Not "disabled": none of the four Figma drawer sets has a State axis and
    // upstream has no disabled prop, so a closed drawer is absent rather than
    // greyed out.
    testWidgets('a closed drawer is not in the tree at all', (tester) async {
      await tester.pumpWidget(
        app(const FluentDrawer(child: SizedBox.expand(key: body))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(body), findsNothing);
      expect(
        colouredBoxes(tester),
        isNot(contains(light.colors.backgroundOverlay)),
      );
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a closed drawer intercepts no pointer', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        app(
          Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  key: outside,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
              const FluentDrawer(child: SizedBox.expand(key: body)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(600, 300));
      expect(taps, 1, reason: 'no scrim is swallowing the tap');
    });
  });

  group('keyboard and focus', () {
    testWidgets('Escape dismisses', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          FluentDrawer(
            open: true,
            onDismiss: () => dismissed++,
            child: const SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, 1);
    });

    testWidgets('a tap on the scrim dismisses', (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(
        app(
          FluentDrawer(
            open: true,
            onDismiss: () => dismissed++,
            child: const SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(600, 300));
      expect(dismissed, 1);
    });

    testWidgets('Tab is trapped inside the panel', (tester) async {
      final inA = FocusNode(debugLabel: 'inA');
      final inB = FocusNode(debugLabel: 'inB');
      final out = FocusNode(debugLabel: 'out');
      addTearDown(inA.dispose);
      addTearDown(inB.dispose);
      addTearDown(out.dispose);

      await tester.pumpWidget(
        app(
          Stack(
            children: <Widget>[
              Focus(
                focusNode: out,
                child: const SizedBox(key: outside, width: 10, height: 10),
              ),
              FluentDrawer(
                open: true,
                child: Column(
                  key: body,
                  children: <Widget>[
                    Focus(
                      focusNode: inA,
                      child: const SizedBox(width: 10, height: 10),
                    ),
                    Focus(
                      focusNode: inB,
                      child: const SizedBox(width: 10, height: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Six presses is three times round a two-stop panel; if the trap leaked,
      // one of them would land outside.
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          inA.hasFocus || inB.hasFocus,
          isTrue,
          reason: 'press ${i + 1} left the panel',
        );
        expect(out.hasFocus, isFalse);
      }
    });

    testWidgets('focus returns to the trigger on close', (tester) async {
      final trigger = FocusNode(debugLabel: 'trigger');
      final inside = FocusNode(debugLabel: 'inside');
      addTearDown(trigger.dispose);
      addTearDown(inside.dispose);

      Widget tree({required bool open}) => app(
        Stack(
          children: <Widget>[
            Focus(
              focusNode: trigger,
              child: const SizedBox(key: outside, width: 10, height: 10),
            ),
            FluentDrawer(
              open: open,
              child: Focus(
                focusNode: inside,
                child: const SizedBox(key: body, width: 10, height: 10),
              ),
            ),
          ],
        ),
      );

      await tester.pumpWidget(tree(open: false));
      trigger.requestFocus();
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isTrue);

      await tester.pumpWidget(tree(open: true));
      await tester.pumpAndSettle();
      inside.requestFocus();
      await tester.pumpAndSettle();
      expect(trigger.hasPrimaryFocus, isFalse);

      await tester.pumpWidget(tree(open: false));
      await tester.pumpAndSettle();
      expect(
        trigger.hasPrimaryFocus,
        isTrue,
        reason: 'the drawer must hand focus back where it found it',
      );
    });
  });

  group('semantics', () {
    testWidgets('an overlay drawer scopes and names its route', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const FluentDrawer(
            open: true,
            semanticLabel: 'Settings',
            child: SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.bySemanticsLabel('Settings'));
      expect(node.label, 'Settings');
      expect(node.flagsCollection.scopesRoute, isTrue);
      expect(node.flagsCollection.namesRoute, isTrue);
      handle.dispose();
    });

    testWidgets('an inline drawer is a named container, not a route', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const Row(
            children: <Widget>[
              FluentDrawer(
                type: FluentDrawerType.inline,
                open: true,
                semanticLabel: 'Navigation',
                child: SizedBox.expand(key: body),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(FluentDrawer));
      expect(node.label, 'Navigation');
      expect(node.flagsCollection.scopesRoute, isFalse);
      handle.dispose();
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);
      await tester.pumpWidget(
        app(
          FluentDrawerTheme(
            style: FluentDrawerStyle.from(backgroundColor: themed),
            child: FluentDrawer(
              open: true,
              style: FluentDrawerStyle.from(backgroundColor: explicit),
              child: const SizedBox.expand(key: body),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FluentDrawer(
            open: true,
            style: FluentDrawerStyle.from(width: 200),
            child: const SizedBox.expand(key: body),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(panelOf().first).width, 200);
      expect(
        decorationOf(tester).color,
        light.colors.neutralBackground1,
        reason: 'overriding width must not drop the fill',
      );
      expect(decorationOf(tester).boxShadow, isNotNull);
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentDrawerBaseState(
        open: true,
        position: FluentDrawerPosition.start,
        child: SizedBox.expand(key: body),
      );
      const mine = Color(0xFF00FF00);

      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: buildFluentDrawer(
                base,
                FluentDrawerStyle.from(
                  backgroundColor: mine,
                  width: 240,
                  borderColor: const Color(0xFF0000FF),
                  borderWidth: 2,
                ),
                const <WidgetState>{},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(decorationOf(tester).color, mine);
      expect(tester.getSize(panelOf().first).width, 240);
      expect((decorationOf(tester).border! as BorderDirectional).end.width, 2);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentDrawerState(
        open: true,
        type: FluentDrawerType.inline,
        size: FluentDrawerSize.medium,
        child: const SizedBox.expand(key: body),
      );
      final adjusted = resolveFluentDrawerStyle(
        state,
        light,
      ).merge(FluentDrawerStyle.from(width: 100));

      await tester.pumpWidget(
        app(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: buildFluentDrawer(state, adjusted, const <WidgetState>{}),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.getSize(panelOf().first).width, 100);
      expect(decorationOf(tester).color, light.colors.neutralBackground1);
    });
  });
}
