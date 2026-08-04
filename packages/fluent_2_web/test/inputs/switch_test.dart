import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSwitch` is a two-part component — a track that recolours and a thumb
/// that travels — so these tests assert the two independently. Both animate on
/// the same 200ms `curveEasyEase` spec, and the thumb's travel is a hardcoded
/// 20 (medium) / 16 (small), never a fraction of the track.
///
/// The `pixel fidelity against Figma` group pins the medium ramp against
/// `test/fixtures/switch.json`. The Figma set has no Size axis at all, so the
/// small ramp's numbers still come from upstream's `useSwitchStyles.styles.ts`
/// and nothing here can vouch for them.
void main() {
  const key = Key('switch');

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Directionality(
        textDirection: direction,
        child: Center(child: child),
      ),
    ),
  );

  Finder partOf(BoxShape shape) => find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! DecoratedBox) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.shape == shape;
    }),
  );

  /// The track: the only rectangular decorated surface the switch paints.
  BoxDecoration trackOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(partOf(BoxShape.rectangle)).decoration
          as BoxDecoration;

  /// The thumb: the only circular one.
  BoxDecoration thumbOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(partOf(BoxShape.circle)).decoration
          as BoxDecoration;

  /// How far the thumb has travelled from the track's leading edge, in the
  /// reading direction.
  double travelOf(WidgetTester tester, {required TextDirection direction}) {
    final track = tester.getRect(partOf(BoxShape.rectangle));
    final thumb = tester.getRect(partOf(BoxShape.circle));
    final inset = (track.height - thumb.height) / 2;
    final leading = direction == TextDirection.ltr
        ? thumb.left - track.left
        : track.right - thumb.right;
    return leading - inset;
  }

  // At most once per test: the mouse tracker asserts on a device being added
  // twice, so a loop that hovers each iteration is not an option.
  Future<void> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
  }

  group('geometry', () {
    testWidgets('track, thumb and travel per size', (tester) async {
      // Medium is Figma's: a 40x20 track and a 14 thumb, pinned against the
      // fixture below. Small has no Figma counterpart — the set carries no Size
      // axis — so 32x16 and 11.2 are upstream's, and 11.2 is the same 0.7 of
      // its track height that Figma's 14 is of 20.
      const expected = {
        FluentSwitchSize.medium: (Size(40, 20), 14.0, 20.0),
        FluentSwitchSize.small: (Size(32, 16), 11.2, 16.0),
      };

      for (final entry in expected.entries) {
        final (track, thumb, travel) = entry.value;
        await pump(
          tester,
          FluentSwitch(
            key: key,
            size: entry.key,
            checked: true,
            onChanged: (_) {},
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(partOf(BoxShape.rectangle)),
          track,
          reason: '${entry.key.name}: track',
        );
        expect(
          tester.getSize(partOf(BoxShape.circle)),
          Size.square(thumb),
          reason: '${entry.key.name}: thumb',
        );
        expect(
          travelOf(tester, direction: TextDirection.ltr),
          closeTo(travel, 0.01),
          reason: '${entry.key.name}: travel',
        );
      }
    });

    testWidgets('unchecked parks the thumb at the leading edge', (
      tester,
    ) async {
      await pump(tester, FluentSwitch(key: key, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(travelOf(tester, direction: TextDirection.ltr), closeTo(0, 0.01));
    });

    testWidgets('the thumb travels toward the trailing edge in RTL', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwitch(key: key, checked: true, onChanged: (_) {}),
        direction: TextDirection.rtl,
      );
      await tester.pumpAndSettle();
      // Griffel flips the translate for RTL, so the offset is directional and
      // the thumb must move right-to-left.
      expect(travelOf(tester, direction: TextDirection.rtl), closeTo(20, 0.01));
      final track = tester.getRect(partOf(BoxShape.rectangle));
      final thumb = tester.getRect(partOf(BoxShape.circle));
      expect(thumb.left - track.left, closeTo(3, 0.01));
    });

    testWidgets('every label position places the label and keeps the height', (
      tester,
    ) async {
      for (final position in FluentSwitchLabelPosition.values) {
        await pump(
          tester,
          FluentSwitch(
            key: key,
            labelPosition: position,
            onChanged: (_) {},
            label: const Text('Label'),
          ),
        );
        await tester.pumpAndSettle();

        final track = tester.getRect(partOf(BoxShape.rectangle));
        final label = tester.getRect(find.text('Label'));
        switch (position) {
          case FluentSwitchLabelPosition.after:
            expect(label.left, greaterThan(track.right));
          case FluentSwitchLabelPosition.before:
            expect(label.right, lessThan(track.left));
          case FluentSwitchLabelPosition.above:
            expect(label.bottom, lessThanOrEqualTo(track.top));
        }
        if (position != FluentSwitchLabelPosition.above) {
          // Track 20 + 8 margin top and bottom; the label's 20px line box sits
          // inside the same 36, which is why upstream's compensating negative
          // margin computes to zero.
          expect(
            tester.getSize(find.byKey(key)).height,
            36,
            reason: '${position.name}: height',
          );
        }
      }
    });
  });

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('switch');
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

    SpecVariant figma(
      String layout, {
      required bool checked,
      String state = 'Rest',
    }) => spec.variant(<String, String>{
      'Layout': layout,
      'Checked': checked ? 'True' : 'False',
      'State': state,
    });

    /// Compares a painted colour with the fixture's.
    ///
    /// A zero-alpha Figma colour is compared on alpha alone: Figma stores a
    /// fully transparent token as transparent *white* because it cannot hold a
    /// colour without an RGB triple, while CSS `transparent` — and therefore
    /// core — is transparent black. Both are invisible; see
    /// `doc/token-divergences.md`.
    void expectColor(Color? actual, Color? expected, String reason) {
      if (expected == null) return;
      expect(actual, isNotNull, reason: reason);
      if (expected.a == 0) {
        expect(actual!.a, 0, reason: '$reason (transparent)');
        return;
      }
      expect(actual!.toARGB32(), expected.toARGB32(), reason: reason);
    }

    testWidgets('the medium track and thumb are the sizes Figma draws', (
      tester,
    ) async {
      for (final checked in <bool>[false, true]) {
        final variant = figma('Switch', checked: checked);
        await pump(
          tester,
          FluentSwitch(key: key, checked: checked, onChanged: (_) {}),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(key)),
          variant.size,
          reason: '${variant.name}: the whole control',
        );
        expect(
          tester.getSize(partOf(BoxShape.rectangle)),
          variant.part('Track').size,
          reason: '${variant.name}: track',
        );
        expect(
          tester.getSize(partOf(BoxShape.circle)),
          variant.part('Thumb').size,
          reason: '${variant.name}: thumb',
        );
      }
    });

    testWidgets('the thumb rests the same distance from either end', (
      tester,
    ) async {
      final variant = figma('Switch', checked: true);
      final track = variant.part('Track').size;
      final thumb = variant.part('Thumb').size;
      // Figma centres a 14 thumb in a 20 track, so the inset is 3 at both ends
      // and the travel is whatever is left of the 40.
      final inset = (track.height - thumb.height) / 2;

      await pump(
        tester,
        FluentSwitch(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();

      final trackRect = tester.getRect(partOf(BoxShape.rectangle));
      final thumbRect = tester.getRect(partOf(BoxShape.circle));
      expect(trackRect.right - thumbRect.right, closeTo(inset, 0.01));
      expect(
        travelOf(tester, direction: TextDirection.ltr),
        closeTo(track.width - 2 * inset - thumb.width, 0.01),
      );
    });

    testWidgets('the track is a hairline capsule', (tester) async {
      final track = figma('Switch', checked: false).part('Track');
      await pump(tester, FluentSwitch(key: key, onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(trackOf(tester).border!.top.width, track.strokeWidth);
      // Figma writes the radius as a literal 10 rather than binding the
      // circular token, and 10 is exactly half a 20-high track — a capsule.
      expect(track.radius!.topLeft.x, track.size.height / 2);
      expect(
        trackOf(tester).borderRadius!.resolve(TextDirection.ltr).topLeft.x,
        greaterThanOrEqualTo(track.size.height / 2),
      );
    });

    testWidgets('resting and disabled paint the Figma colours', (tester) async {
      for (final checked in <bool>[false, true]) {
        for (final enabled in <bool>[true, false]) {
          final variant = figma(
            'Switch',
            checked: checked,
            state: enabled ? 'Rest' : 'Disabled',
          );
          final track = variant.part('Track');
          await pump(
            tester,
            FluentSwitch(
              key: key,
              checked: checked,
              onChanged: enabled ? (_) {} : null,
            ),
          );
          await tester.pumpAndSettle();

          expectColor(
            trackOf(tester).color,
            track.fill,
            '${variant.name}: track fill',
          );
          expectColor(
            trackOf(tester).border?.top.color,
            track.stroke,
            '${variant.name}: track stroke',
          );
          expectColor(
            thumbOf(tester).color,
            variant.part('Thumb').fill,
            '${variant.name}: thumb fill',
          );
        }
      }
    });

    testWidgets('hover paints the Figma colours', (tester) async {
      final variant = figma('Switch', checked: true, state: 'Hover');
      await pump(
        tester,
        FluentSwitch(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      await hover(tester);
      await tester.pumpAndSettle();

      expectColor(
        trackOf(tester).color,
        variant.part('Track').fill,
        '${variant.name}: track fill',
      );
      expectColor(
        thumbOf(tester).color,
        variant.part('Thumb').fill,
        '${variant.name}: thumb fill',
      );
    });

    testWidgets('pressed paints the Figma colours', (tester) async {
      final variant = figma('Switch', checked: true, state: 'Pressed');
      await pump(
        tester,
        FluentSwitch(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();

      expectColor(
        trackOf(tester).color,
        variant.part('Track').fill,
        '${variant.name}: track fill',
      );
    });

    testWidgets('every label layout is the height Figma draws', (tester) async {
      const layouts = <FluentSwitchLabelPosition, String>{
        FluentSwitchLabelPosition.after: 'Switch+Label after',
        FluentSwitchLabelPosition.before: 'Switch+Label before',
        FluentSwitchLabelPosition.above: 'Switch+Label above',
      };
      for (final entry in layouts.entries) {
        final variant = figma(entry.value, checked: false);
        await pump(
          tester,
          FluentSwitch(
            key: key,
            labelPosition: entry.key,
            onChanged: (_) {},
            label: const Text('Label'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: variant.name,
        );
      }
    });

    test('the label and track insets are the ones Figma binds', () {
      EdgeInsets labelPaddingFor(FluentSwitchLabelPosition position) =>
          resolveFluentSwitchStyle(
                resolveFluentSwitchState(
                  labelPosition: position,
                  label: const Text('Label'),
                ),
                theme,
              ).labelPadding!
              .resolve(const <WidgetState>{})!
              .resolve(TextDirection.ltr);

      // Only the horizontal insets are compared for `after` and `before`:
      // Figma centres a 20-tall label frame in the 36-tall row, this port pads
      // it to the same 36 and aligns to the top, and both put the text at 8.
      final after = labelPaddingFor(FluentSwitchLabelPosition.after);
      final afterFigma = figma(
        'Switch+Label after',
        checked: false,
      ).part('Label after').padding!;
      expect(after.left, afterFigma.left);
      expect(after.right, afterFigma.right);

      final before = labelPaddingFor(FluentSwitchLabelPosition.before);
      final beforeFigma = figma(
        'Switch+Label before',
        checked: false,
      ).part('Label before').padding!;
      expect(before.left, beforeFigma.left);
      expect(before.right, beforeFigma.right);

      // Above is the one layout where the vertical insets are Figma's too: the
      // 4 sits above the label on the wrapper and there is nothing below it.
      final above = labelPaddingFor(FluentSwitchLabelPosition.above);
      final aboveVariant = figma('Switch+Label above', checked: false);
      final aboveFigma = aboveVariant.part('Label Above').padding!;
      expect(above.left, aboveFigma.left);
      expect(above.right, aboveFigma.right);
      expect(above.top, aboveVariant.part('Horizontal labels').padding!.top);
      expect(above.bottom, 0);
    });

    test('the indicator keeps its full margin in every layout', () {
      // Figma's `.SwitchBase` is 56x36 in all 40 variants, so the track margin
      // never shrinks — not even with the label stacked above it. Read off the
      // checked variants: the unchecked ones nest a `.UncheckedBase` under the
      // same layer, carrying the same numbers under a different name.
      for (final entry in <FluentSwitchLabelPosition, String>{
        FluentSwitchLabelPosition.after: 'Switch+Label after',
        FluentSwitchLabelPosition.before: 'Switch+Label before',
        FluentSwitchLabelPosition.above: 'Switch+Label above',
      }.entries) {
        final expected = figma(
          entry.value,
          checked: true,
        ).part('.SwitchBase').padding!;
        final actual =
            resolveFluentSwitchStyle(
                  resolveFluentSwitchState(
                    labelPosition: entry.key,
                    label: const Text('Label'),
                  ),
                  theme,
                ).trackPadding!
                .resolve(const <WidgetState>{})!
                .resolve(TextDirection.ltr);
        expect(actual, expected, reason: entry.value);
      }
    });

    test('the label type ramp is the one Figma binds', () {
      final text = figma('Switch+Label after', checked: false).text!;
      final style = theme.typography.body1;
      expect(style.fontSize, text.fontSize);
      expect(style.height! * style.fontSize!, text.lineHeight);
    });
  });

  group('token selection across every variant axis', () {
    late FluentThemeData theme;
    setUp(() {
      theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    });

    testWidgets('unchecked rest, hover and pressed', (tester) async {
      final c = theme.colors;
      await pump(tester, FluentSwitch(key: key, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, c.transparentBackground);
      expect(trackOf(tester).border!.top.color, c.neutralStrokeAccessible);
      expect(thumbOf(tester).color, c.neutralStrokeAccessible);

      await hover(tester);
      await tester.pumpAndSettle();
      expect(trackOf(tester).border!.top.color, c.neutralStrokeAccessibleHover);
      expect(thumbOf(tester).color, c.neutralStrokeAccessibleHover);

      await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(
        trackOf(tester).border!.top.color,
        c.neutralStrokeAccessiblePressed,
      );
      expect(thumbOf(tester).color, c.neutralStrokeAccessiblePressed);
    });

    testWidgets('checked rest, hover and pressed', (tester) async {
      final c = theme.colors;
      await pump(
        tester,
        FluentSwitch(key: key, checked: true, onChanged: (_) {}),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, c.compoundBrandBackground);
      expect(trackOf(tester).border!.top.color, c.transparentStroke);
      expect(thumbOf(tester).color, c.neutralForegroundInverted);

      await hover(tester);
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, c.compoundBrandBackgroundHover);
      expect(trackOf(tester).border!.top.color, c.transparentStrokeInteractive);

      await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, c.compoundBrandBackgroundPressed);
    });

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      final c = theme.colors;
      for (final checked in <bool>[false, true]) {
        await pump(
          tester,
          FluentSwitch(key: key, checked: checked, label: const Text('L')),
        );
        await tester.pumpAndSettle();

        expect(
          trackOf(tester).color,
          checked ? c.neutralBackgroundDisabled : c.transparentBackground,
          reason: 'checked=$checked: track',
        );
        expect(
          trackOf(tester).border!.top.color,
          checked ? c.transparentStrokeDisabled : c.neutralStrokeDisabled,
          reason: 'checked=$checked: border',
        );
        expect(thumbOf(tester).color, c.neutralForegroundDisabled);
        expect(
          tester.widget<RichText>(find.byType(RichText)).text.style!.color,
          c.neutralForegroundDisabled,
          reason: 'checked=$checked: label',
        );

        // Not a paint job: tapping must change nothing at all.
        await tester.tap(find.byKey(key), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(
          trackOf(tester).border!.top.color,
          checked ? c.transparentStrokeDisabled : c.neutralStrokeDisabled,
          reason: 'checked=$checked: border after interaction',
        );
        expect(
          travelOf(tester, direction: TextDirection.ltr),
          closeTo(checked ? 20 : 0, 0.01),
          reason: 'checked=$checked: thumb must not move',
        );
      }
    });

    testWidgets('a disabled switch never adopts the hover token', (
      tester,
    ) async {
      await pump(tester, const FluentSwitch(key: key));
      await tester.pumpAndSettle();
      await hover(tester);
      await tester.pumpAndSettle();
      expect(
        trackOf(tester).border!.top.color,
        theme.colors.neutralStrokeDisabled,
      );
    });

    testWidgets('the label type ramp follows the size', (tester) async {
      for (final size in FluentSwitchSize.values) {
        await pump(
          tester,
          FluentSwitch(
            key: key,
            size: size,
            onChanged: (_) {},
            label: const Text('Label'),
          ),
        );
        final style = tester
            .widget<RichText>(find.byType(RichText))
            .text
            .style!;
        final expected = size == FluentSwitchSize.medium
            ? theme.typography.body1
            : theme.typography.caption1;
        expect(style.fontSize, expected.fontSize, reason: size.name);
        expect(style.height, expected.height, reason: size.name);
      }
    });
  });

  group('motion', () {
    // Upstream indicator: transitionProperty 'background, border, color',
    // durationNormal (200ms), curveEasyEase. Its child (the thumb) transitions
    // `transform` on the same duration and curve.
    testWidgets('the track tweens between checked and unchecked at 200ms', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      var checked = false;
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => FluentSwitch(
                key: key,
                checked: checked,
                onChanged: (value) => setState(() => checked = value),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = trackOf(tester).color!;
      expect(
        midway,
        isNot(theme.colors.compoundBrandBackground),
        reason: 'must be mid-tween, not instant',
      );
      expect(midway.a, greaterThan(0), reason: 'fading up from transparent');
      expect(
        travelOf(tester, direction: TextDirection.ltr),
        allOf(greaterThan(0.0), lessThan(20.0)),
        reason: 'the thumb tweens too',
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(trackOf(tester).color, theme.colors.compoundBrandBackground);
      expect(travelOf(tester, direction: TextDirection.ltr), closeTo(20, 0.01));
    });

    testWidgets('reduced motion lands both track and thumb immediately', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      var checked = false;
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => FluentSwitch(
                key: key,
                checked: checked,
                onChanged: (value) => setState(() => checked = value),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(key));
      await tester.pump();
      await tester.pump();
      expect(trackOf(tester).color, theme.colors.compoundBrandBackground);
      expect(travelOf(tester, direction: TextDirection.ltr), closeTo(20, 0.01));
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
        FluentSwitchTheme(
          style: FluentSwitchStyle.from(trackColor: themed),
          child: FluentSwitch(
            key: key,
            style: FluentSwitchStyle.from(trackColor: explicit),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSwitchTheme(
          style: FluentSwitchStyle.from(trackColor: themed),
          child: FluentSwitch(key: key, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentSwitch(
          key: key,
          checked: true,
          style: FluentSwitchStyle.from(thumbSize: 10),
          onChanged: (_) {},
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(partOf(BoxShape.circle)), const Size.square(10));
      expect(
        trackOf(tester).color,
        theme.colors.compoundBrandBackground,
        reason: 'overriding the thumb must not drop the brand track',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSwitchBaseState(
        enabled: true,
        checked: true,
        labelPosition: FluentSwitchLabelPosition.after,
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwitch(
            base,
            FluentSwitchStyle.from(
              trackColor: mine,
              trackSize: const Size(40, 20),
              thumbSize: 14,
              thumbTravel: 20,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, mine);
      expect(travelOf(tester, direction: TextDirection.ltr), closeTo(20, 0.01));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSwitchState(checked: true);
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentSwitchStyle(
        state,
        theme,
      ).merge(FluentSwitchStyle.from(thumbTravel: 8));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwitch(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, theme.colors.compoundBrandBackground);
      expect(travelOf(tester, direction: TextDirection.ltr), closeTo(8, 0.01));
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the switch', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandBackground: magenta},
            child: Center(
              child: FluentSwitch(key: key, checked: true, onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(trackOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final checked in <bool>[false, true]) {
        await pump(
          tester,
          FluentSwitch(key: key, checked: checked, onChanged: (_) {}),
          theme: theme,
        );
        await tester.pumpAndSettle();
        // The checked track's border is `transparentStroke`, which is opaque
        // CanvasText in high contrast — a hardcoded Colors.transparent here
        // would erase the whole outline of a brand-filled switch.
        expect(
          trackOf(tester).border!.top.color.a,
          1.0,
          reason: 'checked=$checked: border must be opaque',
        );
        expect(
          trackOf(tester).border!.top.width,
          FluentStroke.thin,
          reason: 'checked=$checked: border must be drawn',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('toggles on tap and on Space', (tester) async {
      final changes = <bool>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentSwitch(key: key, focusNode: node, onChanged: changes.add),
      );

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(changes, <bool>[true]);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes, <bool>[true, true], reason: 'keyboard activation');
    });

    testWidgets('announces itself as a toggle with its label', (tester) async {
      await pump(
        tester,
        FluentSwitch(
          key: key,
          checked: true,
          onChanged: (_) {},
          label: const Text('Wi-Fi'),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Wi-Fi',
          isToggled: true,
          hasToggledState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a disabled switch still announces its off/on state', (
      tester,
    ) async {
      await pump(tester, const FluentSwitch(key: key, label: Text('Wi-Fi')));
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Wi-Fi',
          hasToggledState: true,
          hasEnabledState: true,
          // FluentInteractive keeps its tap recogniser attached while disabled
          // and drops the callback instead, so the action survives; `isEnabled`
          // is the flag assistive technology gates on.
          hasTapAction: false,
        ),
      );
    });
  });
}
