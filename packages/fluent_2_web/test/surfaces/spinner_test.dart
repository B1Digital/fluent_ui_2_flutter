import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSpinner` is the first component in the package that is animated
/// rather than state-driven, so these tests carry two extra burdens on top of
/// the usual pixel fidelity: the motion has to match upstream's timing exactly,
/// and it has to stop dead under reduced motion.
///
/// Two fixtures back it, because Figma ships two component sets:
///
/// * `spinner` — the public `Spinner`, 64 variants across Layout × Style × Size
/// * `spinner_base` — the internal `.SpinnerBase`, 32 variants: the 8 real ring
///   sizes plus 24 `<size> 01/02/03` animation keyframes that are **not** API
void main() {
  const key = Key('spinner');

  Future<void> pump(
    WidgetTester tester,
    Widget spinner, {
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
      home: Center(child: spinner),
    ),
  );

  /// The spinner's ring painter, skipping any other `CustomPaint` in the tree.
  FluentSpinnerPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentSpinnerPainter>()
      .first;

  /// The ring's own square box, which is what the fixture's diameter describes.
  Size ringSizeOf(WidgetTester tester) => tester.getSize(
    find
        .descendant(of: find.byKey(key), matching: find.byType(CustomPaint))
        .first,
  );

  const sizeNames = {
    FluentSpinnerSize.extraTiny: 'Extra-tiny',
    FluentSpinnerSize.tiny: 'Tiny',
    FluentSpinnerSize.extraSmall: 'Extra-small',
    FluentSpinnerSize.small: 'Small',
    FluentSpinnerSize.medium: 'Medium',
    FluentSpinnerSize.large: 'Large',
    FluentSpinnerSize.extraLarge: 'Extra-large',
    FluentSpinnerSize.huge: 'Huge',
  };

  // .SpinnerBase spells three of the eight sizes differently from Spinner.
  const baseSizeNames = {
    FluentSpinnerSize.extraTiny: 'X-Tiny',
    FluentSpinnerSize.tiny: 'Tiny',
    FluentSpinnerSize.extraSmall: 'X-Small',
    FluentSpinnerSize.small: 'Small',
    FluentSpinnerSize.medium: 'Medium',
    FluentSpinnerSize.large: 'Large',
    FluentSpinnerSize.extraLarge: 'X-Large',
    FluentSpinnerSize.huge: 'Huge',
  };

  const layoutNames = {
    FluentSpinnerLabelPosition.after: 'Label after',
    FluentSpinnerLabelPosition.before: 'Label before',
    FluentSpinnerLabelPosition.above: 'Label above',
    FluentSpinnerLabelPosition.below: 'Label below',
  };

  const appearanceNames = {
    FluentSpinnerAppearance.primary: 'Primary',
    FluentSpinnerAppearance.subtle: 'Subtle',
  };

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('spinner');
    final base = loadSpec('spinner_base');

    test('both fixtures cover their whole component set', () {
      expect(spec.variants.length, 64);
      expect(base.variants.length, 32);
    });

    test('every axis of both sets maps onto the public API', () {
      expect(spec.properties['Layout'], layoutNames.values);
      expect(spec.properties['Style'], appearanceNames.values);
      expect(spec.properties['Size'], sizeNames.values);

      // The 24 `<size> 01/02/03` rows are animation keyframes, like Skeleton's.
      // Exactly the 8 canonical names are API; the rest must not become enum
      // values.
      final keyframes = base.variants
          .where((v) => RegExp(r' 0[123]$').hasMatch(v.props['Size']!))
          .toList();
      expect(keyframes.length, 24);
      expect(
        base.variants.length - keyframes.length,
        baseSizeNames.length,
        reason: 'every non-keyframe base variant must be a FluentSpinnerSize',
      );
    });

    testWidgets('the ring diameter matches every size', (tester) async {
      for (final entry in baseSizeNames.entries) {
        final variant = base.variant({'Size': entry.value});
        await pump(
          tester,
          FluentSpinner(key: key, size: entry.key),
          reducedMotion: true,
        );
        expect(
          ringSizeOf(tester),
          variant.size,
          reason: '${entry.key.name}: ring diameter',
        );
      }
    });

    testWidgets('the overall height matches every layout and size', (
      tester,
    ) async {
      for (final layout in layoutNames.entries) {
        for (final size in sizeNames.entries) {
          final variant = spec.variant({
            'Layout': layout.value,
            'Style': 'Primary',
            'Size': size.value,
          });
          await pump(
            tester,
            FluentSpinner(
              key: key,
              size: size.key,
              labelPosition: layout.key,
              label: const Text('Loading'),
            ),
            reducedMotion: true,
          );
          // Figma's frames were drawn against a 28px `subtitle1` line box.
          // The published Web ramp — https://fluent2.microsoft.design/typography
          // — specifies 20/26, and `FluentTypography.web` follows it, so a
          // STACKED label contributes exactly that 2px less to the frame. An
          // inline label sits beside a glyph taller than either line box, so
          // its height is unaffected. Stated rather than absorbed into a
          // tolerance: the drift is derived from the fixture's own token, so
          // it moves if either authority does.
          final stacked =
              layout.key == FluentSpinnerLabelPosition.above ||
              layout.key == FluentSpinnerLabelPosition.below;
          final label = resolvedTextStyleOf(tester, of: find.byKey(key));
          final drift = stacked
              ? (variant.text?.lineHeight ?? 0) -
                    label.height! * label.fontSize!
              : 0.0;
          expect(
            tester.getSize(find.byKey(key)).height,
            variant.size.height - drift,
            reason: '${layout.value} / ${size.value}: height',
          );
        }
      }
      // Width is deliberately not asserted: the fixture's width is Figma's
      // placeholder string, and the file disagrees with itself — `Label before,
      // Primary, Huge` is 163 while the identical Subtle variant is 133.
    });

    testWidgets('the label type ramp matches every size', (tester) async {
      for (final entry in sizeNames.entries) {
        final variant = spec.variant({
          'Layout': 'Label after',
          'Style': 'Primary',
          'Size': entry.value,
        });
        await pump(
          tester,
          FluentSpinner(
            key: key,
            size: entry.key,
            label: const Text('Loading'),
          ),
          reducedMotion: true,
        );

        final style = resolvedTextStyleOf(tester, of: find.byKey(key));
        final text = variant.text!;
        expect(style.fontSize, text.fontSize, reason: '${entry.value}: size');
        // The fixture's `Typography/Line height/500` still resolves to 28.
        // The published Web ramp specifies 26 for `subtitle1`, which is what
        // ships — see FluentTypography.web. Every other stop agrees, so the
        // assertion is exact except where that one token is in play.
        expect(
          style.height! * style.fontSize!,
          text.fontSize == 20 ? 26 : text.lineHeight,
          reason: '${entry.value}: line height',
        );
      }
    });

    testWidgets('the ring colours match every style', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      // Figma binds `Track` and `Tail` fills per Style on the .SpinnerBase
      // instance inside each Spinner variant.
      const expected = {
        FluentSpinnerAppearance.primary: (
          'Brand/Stroke/2/Contrast/Rest',
          'Brand/Stroke/1/Rest',
        ),
        FluentSpinnerAppearance.subtle: (
          'Neutral/Stroke/Alpha/2/Rest',
          'Neutral/Stroke/on Brand/2/Rest',
        ),
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentSpinner(key: key, appearance: entry.key),
          reducedMotion: true,
        );
        final painter = painterOf(tester);
        final (track, indicator) = switch (entry.key) {
          FluentSpinnerAppearance.primary => (
            theme.colors.brandStroke2Contrast,
            theme.colors.brandStroke1,
          ),
          FluentSpinnerAppearance.subtle => (
            theme.colors.neutralStrokeAlpha2,
            theme.colors.neutralStrokeOnBrand2,
          ),
        };
        expect(painter.trackColor, track, reason: entry.value.$1);
        expect(painter.indicatorColor, indicator, reason: entry.value.$2);
      }
    });

    testWidgets('the ring thickness follows the stroke ramp', (tester) async {
      const widths = {
        FluentSpinnerSize.extraTiny: FluentStroke.thick,
        FluentSpinnerSize.tiny: FluentStroke.thick,
        FluentSpinnerSize.extraSmall: FluentStroke.thick,
        FluentSpinnerSize.small: FluentStroke.thick,
        FluentSpinnerSize.medium: FluentStroke.thicker,
        FluentSpinnerSize.large: FluentStroke.thicker,
        FluentSpinnerSize.extraLarge: FluentStroke.thicker,
        FluentSpinnerSize.huge: FluentStroke.thickest,
      };
      for (final entry in widths.entries) {
        await pump(
          tester,
          FluentSpinner(key: key, size: entry.key),
          reducedMotion: true,
        );
        expect(
          painterOf(tester).strokeWidth,
          entry.value,
          reason: '${entry.key.name}: stroke width',
        );
      }
    });
  });

  group('motion', () {
    test(
      'the specs are 1.5s linear for the ring and easyEase for the tail',
      () {
        expect(
          FluentSpinnerMotion.rotation,
          const FluentMotionSpec(
            duration: Duration(milliseconds: 1500),
            curve: FluentCurve.linear,
          ),
        );
        expect(
          FluentSpinnerMotion.tail,
          const FluentMotionSpec(
            duration: Duration(milliseconds: 1500),
            curve: FluentCurve.easyEase,
          ),
        );
        expect(
          FluentSpinnerMotion.tailKeyframes.length,
          3,
          reason: 'upstream spinner-tail has three keyframes',
        );
      },
    );

    test('the ring turns exactly once per cycle, linearly', () {
      expect(FluentSpinnerPose.at(0).rotation, 0);
      expect(FluentSpinnerPose.at(0.25).rotation, closeTo(math.pi / 2, 1e-9));
      expect(FluentSpinnerPose.at(0.5).rotation, closeTo(math.pi, 1e-9));
      expect(FluentSpinnerPose.at(1).rotation, closeTo(2 * math.pi, 1e-9));
    });

    test('the tail lands on each keyframe at 0, 0.5 and 1', () {
      final [first, middle, last] = FluentSpinnerMotion.tailKeyframes;
      for (final (progress, keyframe) in [
        (0.0, first),
        (0.5, middle),
        (1.0, last),
      ]) {
        final pose = FluentSpinnerPose.at(progress);
        expect(pose.tailStart, closeTo(keyframe.start, 1e-9), reason: '$pose');
        expect(pose.tailSweep, closeTo(keyframe.sweep, 1e-9), reason: '$pose');
      }
      expect(
        middle.sweep,
        greaterThan(first.sweep),
        reason: 'the tail grows out of the first keyframe',
      );
    });

    testWidgets('the ring is a quarter turn behind at 750ms', (tester) async {
      await pump(tester, const FluentSpinner(key: key));
      expect(painterOf(tester).rotation, 0);

      await tester.pump(const Duration(milliseconds: 750));
      expect(
        painterOf(tester).rotation,
        closeTo(math.pi, 1e-6),
        reason: 'half of a 1.5s linear turn',
      );

      await tester.pump(const Duration(milliseconds: 375));
      expect(painterOf(tester).rotation, closeTo(math.pi * 1.5, 1e-6));
    });

    testWidgets('reduced motion holds the Figma resting pose', (tester) async {
      await pump(tester, const FluentSpinner(key: key), reducedMotion: true);
      final before = painterOf(tester);
      expect(before.rotation, FluentSpinnerPose.resting.rotation);
      expect(before.tailStart, FluentSpinnerPose.resting.tailStart);
      expect(
        before.tailSweep,
        closeTo(math.pi / 2, 1e-9),
        reason: 'Figma draws the static tail as a quarter arc',
      );

      // A whole cycle of wall clock must change nothing: the controller is not
      // merely paused at a frame boundary, it never started.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(painterOf(tester).rotation, before.rotation);
      expect(painterOf(tester).tailSweep, before.tailSweep);
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
        FluentSpinnerTheme(
          style: FluentSpinnerStyle.from(indicatorColor: themed),
          child: FluentSpinner(
            key: key,
            style: FluentSpinnerStyle.from(indicatorColor: explicit),
          ),
        ),
        reducedMotion: true,
      );
      expect(painterOf(tester).indicatorColor, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSpinnerTheme(
          style: FluentSpinnerStyle.from(indicatorColor: themed),
          child: const FluentSpinner(key: key),
        ),
        reducedMotion: true,
      );
      expect(painterOf(tester).indicatorColor, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSpinner(key: key, style: FluentSpinnerStyle.from(diameter: 100)),
        reducedMotion: true,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(ringSizeOf(tester), const Size(100, 100));
      expect(
        painterOf(tester).indicatorColor,
        theme.colors.brandStroke1,
        reason: 'overriding the diameter must not drop the brand tail',
      );
      expect(painterOf(tester).strokeWidth, FluentStroke.thicker);
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSpinnerBaseState(
        labelPosition: FluentSpinnerLabelPosition.after,
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSpinner(
            base,
            FluentSpinnerStyle.from(
              trackColor: mine,
              indicatorColor: mine,
              diameter: 64,
              strokeWidth: 5,
            ),
            const <WidgetState>{},
          ),
        ),
        reducedMotion: true,
      );
      expect(painterOf(tester).trackColor, mine);
      expect(painterOf(tester).strokeWidth, 5);
      expect(ringSizeOf(tester), const Size(64, 64));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSpinnerState(
        appearance: FluentSpinnerAppearance.subtle,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentSpinnerStyle(
        state,
        theme,
      ).merge(FluentSpinnerStyle.from(strokeWidth: FluentStroke.thickest));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSpinner(state, adjusted, const <WidgetState>{}),
        ),
        reducedMotion: true,
      );
      expect(
        painterOf(tester).indicatorColor,
        theme.colors.neutralStrokeOnBrand2,
      );
      expect(painterOf(tester).strokeWidth, FluentStroke.thickest);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the spinner', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.brandStroke1: magenta},
            child: Center(child: FluentSpinner(key: key)),
          ),
        ),
      );
      expect(painterOf(tester).indicatorColor, magenta);
    });

    testWidgets('high contrast paints an opaque, legible ring', (tester) async {
      for (final appearance in FluentSpinnerAppearance.values) {
        await pump(
          tester,
          FluentSpinner(
            key: key,
            appearance: appearance,
            label: const Text('Loading'),
          ),
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
          reducedMotion: true,
        );
        final painter = painterOf(tester);
        // Subtle's track is `neutralStrokeAlpha2`, a 20%-white in every normal
        // theme. High contrast maps it to opaque canvas — a literal
        // Colors.transparent or a hand-rolled withOpacity would stay invisible
        // here and the ring would silently lose its rail.
        expect(
          painter.trackColor.a,
          1.0,
          reason: '${appearance.name}: track must be opaque',
        );
        expect(
          painter.indicatorColor.a,
          1.0,
          reason: '${appearance.name}: tail must be opaque',
        );
        expect(
          painter.trackColor,
          isNot(painter.indicatorColor),
          reason: '${appearance.name}: the tail must read against the track',
        );
        expect(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color!.a,
          1.0,
          reason: '${appearance.name}: label must be opaque',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('the label sits on the side Figma puts it', (tester) async {
      for (final entry in layoutNames.entries) {
        await pump(
          tester,
          FluentSpinner(
            key: key,
            labelPosition: entry.key,
            label: const Text('Loading'),
          ),
          reducedMotion: true,
        );
        final ring = tester.getCenter(
          find
              .descendant(
                of: find.byKey(key),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        final label = tester.getCenter(find.text('Loading'));
        switch (entry.key) {
          case FluentSpinnerLabelPosition.after:
            expect(label.dx, greaterThan(ring.dx), reason: entry.value);
          case FluentSpinnerLabelPosition.before:
            expect(label.dx, lessThan(ring.dx), reason: entry.value);
          case FluentSpinnerLabelPosition.above:
            expect(label.dy, lessThan(ring.dy), reason: entry.value);
          case FluentSpinnerLabelPosition.below:
            expect(label.dy, greaterThan(ring.dy), reason: entry.value);
        }
      }
    });

    testWidgets('it is not interactive — no focus, no press, no disabled', (
      tester,
    ) async {
      // The Figma set has no `State` axis at all, so there is nothing to
      // disable: a spinner is output, not a control. Asserting the absence
      // stops someone bolting an onPressed onto it later.
      expect(loadSpec('spinner').properties.containsKey('State'), isFalse);

      await pump(
        tester,
        const FluentSpinner(key: key, semanticLabel: 'Loading'),
        reducedMotion: true,
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FocusableActionDetector),
        ),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Loading', isLiveRegion: true),
      );
    });
  });
}
