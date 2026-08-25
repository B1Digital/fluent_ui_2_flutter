import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// The Figma `Swatch` set names its sizes `ExtraSmall`/`Small`/`Medium`/
/// `Large`; the ` (Default)` marker is already stripped by the extractor.
const Map<FluentSwatchSize, String> _sizeNames = <FluentSwatchSize, String>{
  FluentSwatchSize.extraSmall: 'ExtraSmall',
  FluentSwatchSize.small: 'Small',
  FluentSwatchSize.medium: 'Medium',
  FluentSwatchSize.large: 'Large',
};

/// The sample colour every Figma variant is filled with —
/// `Colors/Shared/Hot pink/Primary`. Using it in the tests means a fill
/// assertion can be read straight off the fixture.
const Color _hotPink = Color(0xFFE3008C);

void main() {
  const key = Key('swatch');

  FluentThemeData lightTheme() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget swatch, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? lightTheme(),
      home: Center(child: swatch),
    ),
  );

  /// The swatch's own decorated surface, skipping the focus ring's CustomPaint.
  BoxDecoration decorationOf(WidgetTester tester, {Key of = key}) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(of),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  /// Every decorated box under the swatch, outermost first. A selected swatch
  /// has two: the brand band and the `strokeFocus1` hairline nested inside it.
  List<BoxDecoration> decorationsOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .toList();

  FluentSwatchMarkPainter markPainterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.foregroundPainter)
      .whereType<FluentSwatchMarkPainter>()
      .first;

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump();
    return mouse;
  }

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('swatch');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 48);
      expect(spec.properties['State'], <String>[
        'Rest',
        'Hover',
        'Pressed',
        'Disabled',
        'Empty',
        'Transparent',
      ]);
      expect(spec.properties['Size'], _sizeNames.values.toList());
      expect(spec.properties['Style'], <String>['Color', 'Icon', 'Image']);
    });

    testWidgets('every one of the 48 variants matches its frame', (
      tester,
    ) async {
      // The exhaustive sweep goes through the recomposition split rather than
      // the widget: `states` can then be stated outright instead of being
      // driven by a gesture, so Hover and Pressed are as cheap as Rest and all
      // 48 rows are covered in one pump each.
      final theme = lightTheme();

      for (final variant in spec.variants) {
        final size = _sizeNames.entries
            .firstWhere((e) => e.value == variant.props['Size'])
            .key;
        final style = variant.props['Style']!;
        final states = switch (variant.props['State']!) {
          'Hover' => <WidgetState>{WidgetState.hovered},
          'Pressed' => <WidgetState>{WidgetState.pressed},
          'Disabled' => <WidgetState>{WidgetState.disabled},
          _ => <WidgetState>{},
        };
        final kind = switch (variant.props['State']!) {
          'Empty' => FluentSwatchKind.empty,
          'Transparent' => FluentSwatchKind.transparent,
          _ =>
            style == 'Image' ? FluentSwatchKind.image : FluentSwatchKind.color,
        };

        final state = resolveFluentSwatchState(
          enabled: !states.contains(WidgetState.disabled),
          kind: kind,
          size: size,
          color: kind == FluentSwatchKind.color ? _hotPink : null,
          icon: style == 'Icon'
              ? const Icon(FluentIcons.checkmark_20_filled)
              : null,
        );

        await pump(
          tester,
          KeyedSubtree(
            key: key,
            child: buildFluentSwatch(
              state,
              resolveFluentSwatchStyle(state, theme),
              states,
            ),
          ),
        );

        expectSpec(tester, find.byKey(key), variant);
      }
    });

    testWidgets('the ring width ramp is Figma\'s, per size and state', (
      tester,
    ) async {
      // Figma paints the ring INSIDE the frame, so the swatch never grows.
      // ExtraSmall carries every band one step thinner than its siblings, and
      // Small pressed is 3 — not the 2 `useColorSwatchStyles` gives it.
      final theme = lightTheme();

      for (final entry in _sizeNames.entries) {
        for (final stateName in const <String>['Hover', 'Pressed']) {
          final variant = spec.variant({
            'State': stateName,
            'Size': entry.value,
            'Style': 'Color',
          });
          final part = variant.part('ColorSwatch');
          final states = <WidgetState>{
            stateName == 'Hover' ? WidgetState.hovered : WidgetState.pressed,
          };
          final state = resolveFluentSwatchState(
            size: entry.key,
            color: _hotPink,
          );

          await pump(
            tester,
            KeyedSubtree(
              key: key,
              child: buildFluentSwatch(
                state,
                resolveFluentSwatchStyle(state, theme),
                states,
              ),
            ),
          );

          final border = decorationOf(tester).border!.top;
          expect(
            border.width,
            part.strokeWidth,
            reason: '${variant.name}: ring width',
          );
          expect(
            border.color,
            stateName == 'Hover'
                ? theme.colors.compoundBrandStroke
                : theme.colors.compoundBrandStrokePressed,
            reason:
                '${variant.name}: ring token '
                '(${part.token('strokes')})',
          );
        }
      }
    });

    testWidgets('the resting ring is 1px transparentStroke on every style', (
      tester,
    ) async {
      // Pins a deliberate divergence. Figma paints NO stroke at rest — the
      // rectangle keeps an authored `strokeWeight` of 1 with an empty paint
      // list — while upstream declares `1px solid colorTransparentStroke`. The
      // two are pixel-identical in light and dark; in high contrast the token
      // turns opaque and is the only thing outlining a dark swatch on a dark
      // canvas, which is why React wins here.
      final theme = lightTheme();

      for (final kind in const <FluentSwatchKind>[
        FluentSwatchKind.color,
        FluentSwatchKind.image,
      ]) {
        final variant = spec.variant({
          'State': 'Rest',
          'Size': 'Medium',
          'Style': kind == FluentSwatchKind.color ? 'Color' : 'Image',
        });
        expect(
          variant
              .part(
                kind == FluentSwatchKind.color ? 'ColorSwatch' : 'ImageSwatch',
              )
              .strokeWidth,
          0,
          reason: 'Figma paints no resting stroke',
        );

        final state = resolveFluentSwatchState(
          kind: kind,
          color: kind == FluentSwatchKind.color ? _hotPink : null,
        );
        await pump(
          tester,
          KeyedSubtree(
            key: key,
            child: buildFluentSwatch(
              state,
              resolveFluentSwatchStyle(state, theme),
              const <WidgetState>{},
            ),
          ),
        );

        final border = decorationOf(tester).border!.top;
        expect(border.width, FluentStroke.thin);
        expect(border.color, theme.colors.transparentStroke);
      }
    });

    testWidgets('a colour swatch fills with the colour it was given', (
      tester,
    ) async {
      final variant = spec.variant({
        'State': 'Rest',
        'Size': 'Medium',
        'Style': 'Color',
      });
      expect(variant.part('ColorSwatch').fill, _hotPink);

      await pump(
        tester,
        const FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
        ),
      );
      expect(decorationOf(tester).color, _hotPink);
    });

    testWidgets('empty draws neutralForeground4 as a 1px dashed rule', (
      tester,
    ) async {
      final theme = lightTheme();
      for (final entry in _sizeNames.entries) {
        final variant = spec.variant({
          'State': 'Empty',
          'Size': entry.value,
          'Style': 'Color',
        });
        final part = variant.part('EmptySwatch');
        expect(part.token('strokes'), 'Neutral/Foreground/4/Rest');
        expect(part.strokeWidth, FluentStroke.thin);

        await pump(
          tester,
          FluentSwatch.empty(
            key: key,
            size: entry.key,
            semanticLabel: 'No colour yet',
            onPressed: () {},
          ),
        );

        // A dashed rule has no BoxDecoration form, so it moves to the painter
        // and the decoration draws no border at all.
        expect(decorationOf(tester).border, isNull);
        final painter = markPainterOf(tester);
        expect(painter.dashColor, theme.colors.neutralForeground4);
        expect(painter.dashWidth, part.strokeWidth);
        expect(painter.dashPattern, <double>[2, 2]);
        expect(painter.slashColor, isNull);
        expect(
          decorationOf(tester).color,
          theme.colors.transparentBackground,
          reason: 'never Colors.transparent — the token turns opaque in HC',
        );
      }
    });

    testWidgets('transparent draws a grey square struck through in red', (
      tester,
    ) async {
      for (final entry in _sizeNames.entries) {
        final variant = spec.variant({
          'State': 'Transparent',
          'Size': entry.value,
          'Style': 'Color',
        });
        final outline = variant.part('TransparentSwatch');
        final bar = variant.part('TransparentSwatch-line');
        expect(outline.token('strokes'), 'Colors/Neutral/Grey-50');
        expect(outline.strokeWidth, FluentStroke.thin);
        expect(bar.strokeWidth, FluentStroke.thick);
        expect(
          bar.tokens,
          isEmpty,
          reason:
              'the bar is the one value in the set Figma leaves untokenised',
        );

        await pump(
          tester,
          FluentSwatch.transparent(
            key: key,
            size: entry.key,
            semanticLabel: 'No colour',
            onPressed: () {},
          ),
        );

        final border = decorationOf(tester).border!.top;
        expect(border.color, FluentGrey.at(50));
        expect(border.color, outline.stroke);
        expect(border.width, outline.strokeWidth);

        final painter = markPainterOf(tester);
        expect(painter.slashColor, kFluentSwatchTransparentMark);
        expect(painter.slashColor, bar.stroke);
        expect(painter.slashWidth, bar.strokeWidth);
        expect(painter.dashColor, isNull);
      }
    });

    testWidgets('disabled keeps the colour and adds the prohibited mark', (
      tester,
    ) async {
      final variant = spec.variant({
        'State': 'Disabled',
        'Size': 'Medium',
        'Style': 'Color',
      });
      expect(variant.part('DisabledSwatch').fill, _hotPink);

      await pump(
        tester,
        const FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
        ),
      );

      expect(decorationOf(tester).color, _hotPink);
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        findsOneWidget,
      );
      final icon = tester.widget<IconTheme>(
        find
            .descendant(of: find.byKey(key), matching: find.byType(IconTheme))
            .last,
      );
      expect(icon.data.color, lightTheme().colors.neutralForegroundInverted);
    });

    testWidgets('the Shape collection drives the corner radius', (
      tester,
    ) async {
      // `Swatch/Default` resolves Rounded → Corner radius/Medium, Circular →
      // Corner radius/Circular, Square → Corner radius/None, and the component
      // set pins Square — which is why every variant frame reads 0.
      final square = spec.variant({
        'State': 'Rest',
        'Size': 'Medium',
        'Style': 'Color',
      });
      expect(square.radius, BorderRadius.zero);

      const expected = <FluentSwatchShape, BorderRadius>{
        FluentSwatchShape.square: BorderRadius.zero,
        FluentSwatchShape.rounded: FluentRadius.allMedium,
        FluentSwatchShape.circular: FluentRadius.allCircular,
      };
      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentSwatch(
            key: key,
            color: _hotPink,
            shape: entry.key,
            semanticLabel: 'Hot pink',
            onPressed: () {},
          ),
        );
        expect(
          decorationOf(tester).borderRadius,
          entry.value,
          reason: entry.key.name,
        );
      }
    });
  });

  group('selection', () {
    testWidgets('selected draws a brand band over a strokeFocus1 hairline', (
      tester,
    ) async {
      // Figma has no Selected variant at all, so `useColorSwatchStyles` is the
      // sole authority: `inset 0 0 0 3px brandStroke1` over
      // `inset 0 0 0 5px strokeFocus1` — a 3px band with a 2px hairline under
      // it — dropping to 2 over 1 on the two small sizes.
      final theme = lightTheme();
      const widths = <FluentSwatchSize, (double, double)>{
        FluentSwatchSize.extraSmall: (FluentStroke.thick, FluentStroke.thin),
        FluentSwatchSize.small: (FluentStroke.thick, FluentStroke.thin),
        FluentSwatchSize.medium: (FluentStroke.thicker, FluentStroke.thick),
        FluentSwatchSize.large: (FluentStroke.thicker, FluentStroke.thick),
      };

      for (final entry in widths.entries) {
        await pump(
          tester,
          FluentSwatch(
            key: key,
            color: _hotPink,
            size: entry.key,
            selected: true,
            semanticLabel: 'Hot pink',
            onPressed: () {},
          ),
        );

        final boxes = decorationsOf(tester);
        expect(boxes.length, 2, reason: '${entry.key.name}: two bands');
        expect(boxes[0].border!.top.color, theme.colors.brandStroke1);
        expect(boxes[0].border!.top.width, entry.value.$1);
        expect(boxes[1].border!.top.color, theme.colors.strokeFocus1);
        expect(boxes[1].border!.top.width, entry.value.$2);
      }
    });

    testWidgets('an unselected swatch has a single band', (tester) async {
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      expect(decorationsOf(tester).length, 1);
    });

    testWidgets('selected is WidgetState.selected, not focus', (tester) async {
      // WidgetState.focused means keyboard-visible focus everywhere in this
      // package; a swatch picker is the place where `selected` is a genuine
      // Fluent Selected state, so the two must not be confused.
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          focusNode: node,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      node.requestFocus();
      await tester.pump();

      // Focus alone must not raise the selection band. The binding starts in
      // touch highlight mode, so this node holds focus without holding
      // `WidgetState.focused` — the focus indicator itself is asserted by the
      // group below, which switches the highlight mode on.
      expect(decorationsOf(tester).length, 1);
      expect(
        decorationOf(tester).border!.top.color,
        lightTheme().colors.transparentStroke,
      );
    });
  });

  group('focus', () {
    /// `WidgetState.focused` means keyboard-VISIBLE focus, which is the AND of
    /// having focus and `FluentInputModality.keyboard`. Flutter's highlight
    /// mode cannot stand in for the second half — it reports `traditional` for
    /// a mouse too — so a real key press is what raises it. Escape flips the
    /// modality without moving focus.
    /// Call this AFTER the widget is pumped and focused: the modality's global
    /// hooks are installed only while something is listening, so a key sent
    /// before the swatch mounts is observed by nobody.
    Future<void> useKeyboardHighlight(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    }

    testWidgets('the ring is drawn inside the swatch, not around it', (
      tester,
    ) async {
      // The one documented exception to this package's outward ring.
      // `useColorSwatchStyles`' reset drops the border and the outline and
      // draws `inset 0 0 0 2px strokeFocus2, inset 0 0 0 3px strokeFocus1`
      // instead; the live picker keeps the swatch 28 square and the neighbour
      // pitch 32 while focused, which an outward ring would have grown. Figma's
      // `State` axis has no Focus variant, so React is unopposed.
      final theme = lightTheme();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          focusNode: node,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );

      expect(find.byType(FluentFocusRing), findsNothing);
      final resting = tester.getSize(find.byKey(key));

      node.requestFocus();
      await tester.pump();
      await useKeyboardHighlight(tester);

      expect(
        tester.getSize(find.byKey(key)),
        resting,
        reason: 'the focus indicator must not change the footprint',
      );
      final boxes = decorationsOf(tester);
      expect(boxes.length, 2, reason: 'a focus band over a hairline');
      expect(boxes[0].border!.top.color, theme.colors.strokeFocus2);
      expect(boxes[0].border!.top.width, FluentStroke.thick);
      expect(boxes[1].border!.top.color, theme.colors.strokeFocus1);
      expect(boxes[1].border!.top.width, FluentStroke.thin);
    });

    testWidgets('focus on a selected swatch widens both bands', (tester) async {
      // `[data-fui-focus-visible]` on a selected swatch is
      // `inset 0 0 0 3px strokeFocus2, inset 0 0 0 5px strokeFocus1` — the
      // focus tone replaces the brand one rather than sitting beside it.
      final theme = lightTheme();
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          selected: true,
          focusNode: node,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      node.requestFocus();
      await tester.pump();
      await useKeyboardHighlight(tester);

      final boxes = decorationsOf(tester);
      expect(boxes[0].border!.top.color, theme.colors.strokeFocus2);
      expect(boxes[0].border!.top.width, FluentStroke.thicker);
      expect(boxes[1].border!.top.color, theme.colors.strokeFocus1);
      expect(boxes[1].border!.top.width, FluentStroke.thick);
    });

    testWidgets('a disabled swatch has no focus band at all', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          focusNode: node,
          semanticLabel: 'Hot pink',
        ),
      );
      node.requestFocus();
      await tester.pump();
      await useKeyboardHighlight(tester);

      expect(decorationsOf(tester).length, 1);
      expect(
        decorationOf(tester).border!.top.color,
        lightTheme().colors.transparentStroke,
      );
    });
  });

  group('motion', () {
    testWidgets('the hover ring lands on the very next frame', (tester) async {
      // Verified against upstream: not one of `useColorSwatchStyles`,
      // `useImageSwatchStyles`, `useEmptySwatchStyles` or
      // `useSwatchPickerStyles` declares a `transition` of any kind. A swatch
      // is instant, and that is a transcription rather than an omission.
      final theme = lightTheme();
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();

      await hover(tester, find.byKey(key));
      expect(
        decorationOf(tester).border!.top.color,
        theme.colors.compoundBrandStroke,
        reason: 'no tween: the ring is fully there on the first frame',
      );
      expect(decorationOf(tester).border!.top.width, FluentStroke.thick);
    });

    testWidgets('nothing in the subtree animates', (tester) async {
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ImplicitlyAnimatedWidget),
        ),
        findsNothing,
        reason: 'an instant component must not carry a motion spec',
      );
    });

    testWidgets('reduced motion changes nothing, because there is none', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: lightTheme(),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: FluentSwatch(
              key: key,
              color: _hotPink,
              semanticLabel: 'Hot pink',
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await hover(tester, find.byKey(key));
      expect(
        decorationOf(tester).border!.top.color,
        lightTheme().colors.compoundBrandStroke,
      );
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
        FluentSwatchTheme(
          style: FluentSwatchStyle.from(backgroundColor: themed),
          child: FluentSwatch(
            key: key,
            color: _hotPink,
            style: FluentSwatchStyle.from(backgroundColor: explicit),
            semanticLabel: 'Hot pink',
            onPressed: () {},
          ),
        ),
      );
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSwatchTheme(
          style: FluentSwatchStyle.from(backgroundColor: themed),
          child: FluentSwatch(
            key: key,
            color: _hotPink,
            semanticLabel: 'Hot pink',
            onPressed: () {},
          ),
        ),
      );
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          style: FluentSwatchStyle.from(borderRadius: FluentRadius.allCircular),
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        decorationOf(tester).color,
        _hotPink,
        reason: 'overriding radius must not drop the fill',
      );
      expect(tester.getSize(find.byKey(key)), const Size.square(28));
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSwatchBaseState(
        enabled: true,
        selected: false,
        kind: FluentSwatchKind.color,
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwatch(
            base,
            FluentSwatchStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
              size: const Size.square(48),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(decorationOf(tester).color, mine);
      expect(decorationOf(tester).borderRadius, FluentRadius.allLarge);
      expect(tester.getSize(find.byKey(key)), const Size.square(48));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSwatchState(
        color: _hotPink,
        size: FluentSwatchSize.large,
      );
      final theme = lightTheme();
      final adjusted = resolveFluentSwatchStyle(
        state,
        theme,
      ).merge(FluentSwatchStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwatch(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(decorationOf(tester).color, _hotPink);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(tester.getSize(find.byKey(key)), const Size.square(32));
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the swatch', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: lightTheme(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandStroke: magenta},
            child: Center(
              child: FluentSwatch(
                key: key,
                color: _hotPink,
                semanticLabel: 'Hot pink',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await hover(tester, find.byKey(key));
      expect(decorationOf(tester).border!.top.color, magenta);
    });

    testWidgets('an override reaches the empty swatch\'s dashed rule too', (
      tester,
    ) async {
      const olive = Color(0xFF6B6B21);
      await tester.pumpWidget(
        FluentApp(
          theme: lightTheme(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralForeground4: olive},
            child: Center(
              child: FluentSwatch.empty(
                key: key,
                semanticLabel: 'No colour yet',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      expect(markPainterOf(tester).dashColor, olive);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
        theme: theme,
      );

      // transparentStroke becomes canvasText in high contrast, so the resting
      // outline that is invisible in light must be opaque here — it is the only
      // thing separating a dark swatch from a dark canvas.
      final border = decorationOf(tester).border;
      expect(border, isNotNull);
      expect(border!.top.color.a, 1.0);
      expect(border.top.width, FluentStroke.thin);
    });

    testWidgets('the transparent swatch stays visible in high contrast', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwatch.transparent(
          key: key,
          semanticLabel: 'No colour',
          onPressed: () {},
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      expect(decorationOf(tester).border!.top.color.a, 1.0);
      expect(markPainterOf(tester).slashColor!.a, 1.0);
    });
  });

  group('behaviour', () {
    testWidgets('fires on tap and on Enter', (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          focusNode: node,
          semanticLabel: 'Hot pink',
          onPressed: () => taps++,
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(taps, 1);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2, reason: 'keyboard activation must work');
    });

    testWidgets('null onPressed disables it for real', (tester) async {
      final theme = lightTheme();
      await pump(
        tester,
        const FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
        ),
      );

      await hover(tester, find.byKey(key));
      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();

      // A disabled swatch reports no hover, so the brand ring never appears.
      expect(
        decorationOf(tester).border!.top.color,
        theme.colors.transparentStroke,
      );
      expect(decorationOf(tester).border!.top.width, FluentStroke.thin);
    });

    testWidgets('a disabled swatch keeps no selection band', (tester) async {
      await pump(
        tester,
        const FluentSwatch(
          key: key,
          color: _hotPink,
          selected: true,
          semanticLabel: 'Hot pink',
        ),
      );
      expect(
        decorationsOf(tester).length,
        1,
        reason: 'disabled outranks selected, as it does everywhere in Fluent',
      );
    });

    testWidgets('it announces itself as one choice among many', (tester) async {
      await pump(
        tester,
        FluentSwatch(
          key: key,
          color: _hotPink,
          selected: true,
          semanticLabel: 'Hot pink',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Hot pink',
          isEnabled: true,
          hasEnabledState: true,
          isChecked: true,
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a disabled swatch announces its disabled state', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentSwatch(
          key: key,
          color: _hotPink,
          semanticLabel: 'Hot pink',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Hot pink',
          hasEnabledState: true,
          hasCheckedState: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
    });
  });
}
