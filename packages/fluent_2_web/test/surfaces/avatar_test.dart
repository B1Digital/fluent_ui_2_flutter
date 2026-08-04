import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentAvatar` is the first consumer of the PALETTE token layer, so these
/// tests are as much a check on `theme.colors.palette.*` as on the widget:
/// every one of the 33 `Avatar color` modes asserts the exact getter its Figma
/// variable resolves to rather than a hex value.
///
/// [expectSpec] is deliberately not used. Every avatar variant frame states
/// `padding: 0` without carrying a `Padding` widget's worth of meaning, and the
/// surface fill lives on the frame's `Fill` child rather than the frame, so the
/// individual resolvers are used directly instead.
void main() {
  const key = Key('avatar');

  String sizeName(FluentAvatarSize size) => size.edge.toInt().toString();

  Future<void> pump(
    WidgetTester tester,
    Widget avatar, {
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
      home: Center(child: avatar),
    ),
  );

  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .first;

  FluentAvatarRingPainter ringOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentAvatarRingPainter>()
      .first;

  IconThemeData iconThemeOf(WidgetTester tester) => tester
      .widgetList<IconTheme>(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
      )
      .last
      .data;

  final spec = loadSpec('avatar');

  group('pixel fidelity against Figma', () {
    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 39);
      expect(spec.properties['Type'], <String>['Image', 'Icon', 'Initials']);
      expect(spec.properties['Size']!.length, FluentAvatarSize.values.length);
      for (final size in FluentAvatarSize.values) {
        expect(spec.properties['Size'], contains(sizeName(size)));
      }
    });

    testWidgets('every size and type matches its variant frame', (
      tester,
    ) async {
      for (final size in FluentAvatarSize.values) {
        for (final type in <String>['Image', 'Icon', 'Initials']) {
          final variant = spec.variant({'Type': type, 'Size': sizeName(size)});

          await pump(
            tester,
            FluentAvatar(
              key: key,
              size: size,
              initials: type == 'Initials' ? 'AL' : null,
              image: type == 'Image' ? const _StubImage() : null,
            ),
          );

          expect(
            tester.getSize(find.byKey(key)),
            Size(variant.size.width, variant.size.height),
            reason: '${variant.name}: size',
          );

          final decoration = decorationOf(tester);
          expect(
            decoration.borderRadius?.resolve(TextDirection.ltr),
            variant.radius,
            reason: '${variant.name}: radius',
          );

          // The `Fill` child is where Figma keeps the surface and the inside
          // stroke; the variant frame itself paints nothing.
          final fill = variant.part('Fill');
          expect(
            decoration.border?.top.width,
            fill.strokeWidth,
            reason: '${variant.name}: inside stroke width',
          );
          expect(
            fill.token('strokeWidth'),
            switch (fill.strokeWidth!) {
              1.0 => 'Stroke width/Thin',
              2.0 => 'Stroke width/Thick',
              3.0 => 'Stroke width/Thicker',
              _ => 'Stroke width/Thickest',
            },
            reason: '${variant.name}: the fixture names the width token',
          );

          if (type == 'Initials') {
            final text = variant.text!;
            final style = resolvedTextStyleOf(tester, of: find.byKey(key));
            expect(
              style.fontSize,
              text.fontSize,
              reason: '${variant.name}: text.fontSize',
            );
            // The fixture's `Typography/Line height/500` still resolves to 28,
            // but the published Web ramp — https://fluent2.microsoft.design/typography
            // — specifies 20/26 for `subtitle1`, and that is what ships. Only that
            // one stop diverges, so the assertion stays exact everywhere else.
            expect(
              style.height! * style.fontSize!,
              text.fontSize == 20 ? 26 : text.lineHeight,
              reason: '${variant.name}: text.lineHeight',
            );
            expect(
              style.fontWeight,
              FontWeight.w600,
              reason: '${variant.name}: Typography/Weight/Semibold',
            );
          }
        }
      }
    });

    testWidgets('the icon ramp is Fluent\'s nominal glyph sizes, not the edge', (
      tester,
    ) async {
      // Read read-only off the `Person` INSTANCE under each Icon variant — the
      // extractor records the glyph's VECTOR ink bounds, which is a different
      // number from the box Fluent instances the icon at.
      const nominal = <FluentAvatarSize, double>{
        FluentAvatarSize.size16: 12,
        FluentAvatarSize.size20: 16,
        FluentAvatarSize.size24: 16,
        FluentAvatarSize.size28: 20,
        FluentAvatarSize.size32: 20,
        FluentAvatarSize.size36: 20,
        FluentAvatarSize.size40: 20,
        FluentAvatarSize.size48: 24,
        FluentAvatarSize.size56: 28,
        FluentAvatarSize.size64: 32,
        FluentAvatarSize.size72: 32,
        FluentAvatarSize.size96: 48,
        FluentAvatarSize.size120: 48,
      };

      for (final entry in nominal.entries) {
        await pump(tester, FluentAvatar(key: key, size: entry.key));
        expect(
          iconThemeOf(tester).size,
          entry.value,
          reason: '${entry.key.name}: glyph box',
        );
      }
    });

    testWidgets('an image fills the avatar and is clipped to its radius', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAvatar(key: key, image: _StubImage(), name: 'Ada'),
      );
      final decoration = decorationOf(tester);
      expect(decoration.image?.image, isA<_StubImage>());
      expect(decoration.image?.fit, BoxFit.cover);
      // A DecorationImage is painted inside the decoration's own shape, so the
      // radius that clips the photo is the same one the border draws on.
      expect(
        decoration.borderRadius?.resolve(TextDirection.ltr),
        FluentRadius.allCircular,
      );
    });
  });

  group('Avatar color: 33 modes, every one an explicit token', () {
    testWidgets('each mode selects the token Figma bound to it', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final c = theme.colors;

      for (final color in FluentAvatarColor.values) {
        final state = resolveFluentAvatarState(color: color);
        final style = resolveFluentAvatarStyle(state, theme);
        const rest = <WidgetState>{};

        final family = color.family;
        final (background, foreground, ring) = switch (color) {
          FluentAvatarColor.neutral => (
            c.neutralBackground6,
            c.neutralForeground3,
            c.brandStroke1,
          ),
          FluentAvatarColor.brand => (
            c.brandBackground,
            c.neutralForegroundOnBrand,
            c.neutralStrokeOnBrand,
          ),
          FluentAvatarColor.overflow => (
            c.neutralBackground1,
            c.neutralForeground1,
            c.transparentStroke,
          ),
          _ => (
            c.palette.background2Rest(family!),
            c.palette.foreground2Rest(family),
            c.palette.strokeActiveRest(family),
          ),
        };

        expect(
          style.backgroundColor!.resolve(rest),
          background,
          reason: '${color.name}: Background',
        );
        expect(
          style.foregroundColor!.resolve(rest),
          foreground,
          reason: '${color.name}: Foreground',
        );
        expect(
          style.ringColor!.resolve(rest),
          ring,
          reason: '${color.name}: Active stroke',
        );
        expect(
          style.borderColor!.resolve(rest),
          color == FluentAvatarColor.overflow
              ? c.neutralStroke2
              : c.transparentStroke,
          reason: '${color.name}: Inside stroke',
        );
      }
    });

    test('exactly the thirty families Figma offers, and no more', () {
      final families = FluentAvatarColor.values
          .map((color) => color.family)
          .whereType<FluentPaletteFamily>()
          .toSet();
      expect(families.length, 30);
      // Absent from the Avatar collection, present in the palette layer.
      expect(families, isNot(contains(FluentPaletteFamily.berry)));
      expect(families, isNot(contains(FluentPaletteFamily.darkOrange)));
      expect(families, isNot(contains(FluentPaletteFamily.green)));
      expect(families, isNot(contains(FluentPaletteFamily.lightGreen)));
      expect(families, isNot(contains(FluentPaletteFamily.yellow)));
    });
  });

  group('shape', () {
    testWidgets('square is Corner radius/Small at every size', (tester) async {
      // The `Avatar shape` collection has two modes and no size axis, so
      // `Avatar corner radius` resolves to Small for a rounded square whatever
      // the avatar's edge. React ramps small/medium/large/xLarge; Figma wins.
      for (final size in FluentAvatarSize.values) {
        await pump(
          tester,
          FluentAvatar(
            key: key,
            size: size,
            shape: FluentAvatarShape.square,
            initials: 'AL',
          ),
        );
        expect(
          decorationOf(tester).borderRadius?.resolve(TextDirection.ltr),
          FluentRadius.allSmall,
          reason: '${size.name}: square radius',
        );
      }
    });
  });

  group('activity ring', () {
    testWidgets('unset paints nothing at all', (tester) async {
      await pump(tester, const FluentAvatar(key: key, initials: 'AL'));
      final ring = ringOf(tester);
      expect(ring.width, 0);
      expect(ring.gap, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('active is one ring-width clear of the avatar', (tester) async {
      // Figma's hidden `Activity ring` rectangle is the avatar inflated by the
      // ring width with its stroke aligned OUTSIDE — 2 up to 48, 3 from 56 up.
      // That is upstream's `margin: calc(-2 * ringWidth); border-width:
      // ringWidth` expressed the other way round.
      const expected = <FluentAvatarSize, double>{
        FluentAvatarSize.size16: FluentStroke.thick,
        FluentAvatarSize.size48: FluentStroke.thick,
        FluentAvatarSize.size56: FluentStroke.thicker,
        FluentAvatarSize.size120: FluentStroke.thicker,
      };
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentAvatar(
            key: key,
            size: entry.key,
            active: FluentAvatarActive.active,
            initials: 'AL',
          ),
        );
        await tester.pumpAndSettle();

        final ring = ringOf(tester);
        expect(ring.width, entry.value, reason: '${entry.key.name}: width');
        expect(ring.gap, entry.value, reason: '${entry.key.name}: gap');
        expect(ring.color, theme.colors.brandStroke1);
        expect(ring.gapColor, theme.colors.neutralBackground1);
        expect(ring.opacity, 1);
      }
    });

    testWidgets('a palette avatar rings in its own Stroke/Active token', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentAvatar(
          key: key,
          color: FluentAvatarColor.cornflower,
          active: FluentAvatarActive.active,
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        ringOf(tester).color,
        theme.colors.palette.strokeActiveRest(FluentPaletteFamily.cornflower),
      );
    });

    testWidgets('inactive collapses the ring and shrinks the avatar', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.inactive,
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle();

      final ring = ringOf(tester);
      expect(ring.width, 0, reason: 'upstream inactive sets margin: 0');
      expect(ring.opacity, 0);

      final transform = tester.widget<Transform>(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
      );
      // entry(0, 0), not getMaxScaleOnAxis: Transform.scale leaves the z axis
      // at 1, which is the maximum and would hide the shrink entirely.
      expect(transform.transform.entry(0, 0), closeTo(0.875, 0.001));
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        closeTo(0.8, 0.001),
      );
    });
  });

  group('motion', () {
    // Verified against microsoft/fluentui master,
    // packages/react-components/react-avatar/library/src/components/Avatar/
    // useAvatarStyles.styles.ts. The root's ::before carries
    // `transition: margin, opacity` at durationUltraSlow, durationSlower on
    // curveEasyEaseMax, curveLinear; the root carries
    // `transition: transform, opacity` at durationUltraSlow, durationFaster on
    // the same curves; and `inactive` swaps the first curve for
    // curveDecelerateMin. There is no transition on anything else.
    test('the four specs are upstream\'s, not invented', () {
      expect(FluentAvatarMotion.arrive.duration, FluentDuration.ultraSlow);
      expect(FluentAvatarMotion.arrive.curve, FluentCurve.easyEaseMax);
      expect(FluentAvatarMotion.leave.duration, FluentDuration.ultraSlow);
      expect(FluentAvatarMotion.leave.curve, FluentCurve.decelerateMin);
      expect(FluentAvatarMotion.ringFade.duration, FluentDuration.slower);
      expect(FluentAvatarMotion.ringFade.curve, FluentCurve.linear);
      expect(FluentAvatarMotion.rootFade.duration, FluentDuration.faster);
      expect(FluentAvatarMotion.rootFade.curve, FluentCurve.linear);
    });

    testWidgets('going inactive is a transition, not a jump', (tester) async {
      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.active,
          initials: 'AL',
        ),
      );
      await tester.pumpAndSettle();
      expect(ringOf(tester).width, FluentStroke.thick);

      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.inactive,
          initials: 'AL',
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final midway = ringOf(tester);
      expect(midway.width, greaterThan(0));
      expect(midway.width, lessThan(FluentStroke.thick));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
      expect(ringOf(tester).width, 0);
    });

    testWidgets('reduced motion lands it on the first frame', (tester) async {
      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.active,
          initials: 'AL',
        ),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();

      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.inactive,
          initials: 'AL',
        ),
        reducedMotion: true,
      );
      await tester.pump();
      expect(ringOf(tester).width, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('an unset avatar has nothing to animate', (tester) async {
      await pump(tester, const FluentAvatar(key: key, initials: 'AL'));
      await tester.pump();
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Transform)),
        findsNothing,
        reason: 'no ring means no wrapper and no ticker',
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
        FluentAvatarTheme(
          style: FluentAvatarStyle.from(backgroundColor: themed),
          child: FluentAvatar(
            key: key,
            initials: 'AL',
            style: FluentAvatarStyle.from(backgroundColor: explicit),
          ),
        ),
      );
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentAvatarTheme(
          style: FluentAvatarStyle.from(backgroundColor: themed),
          child: const FluentAvatar(key: key, initials: 'AL'),
        ),
      );
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentAvatar(
          key: key,
          initials: 'AL',
          style: FluentAvatarStyle.from(diameter: 44),
        ),
      );
      expect(tester.getSize(find.byKey(key)), const Size(44, 44));
      expect(
        decorationOf(tester).color,
        theme.colors.neutralBackground6,
        reason: 'overriding the diameter must not drop the surface token',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentAvatarBaseState(
        active: FluentAvatarActive.unset,
        initials: 'ZZ',
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentAvatar(
            base,
            FluentAvatarStyle.from(
              backgroundColor: mine,
              diameter: 50,
              borderRadius: BorderRadius.zero,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(decorationOf(tester).color, mine);
      expect(tester.getSize(find.byKey(key)), const Size(50, 50));
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentAvatarState(
        color: FluentAvatarColor.marigold,
        size: FluentAvatarSize.size56,
        initials: 'AL',
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentAvatarStyle(
        state,
        theme,
      ).merge(FluentAvatarStyle.from(diameter: 60));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentAvatar(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(
        decorationOf(tester).color,
        theme.colors.palette.background2Rest(FluentPaletteFamily.marigold),
      );
      expect(tester.getSize(find.byKey(key)), const Size(60, 60));
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the avatar', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralBackground6: magenta},
            child: Center(
              child: FluentAvatar(key: key, initials: 'AL'),
            ),
          ),
        ),
      );
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      // The inside stroke is `Neutral/Stroke/Transparent/Rest` in 32 of the 33
      // colour modes. Invisible in light and dark by design — and OPAQUE in
      // high contrast, where it is the only thing separating one avatar from
      // the surface behind it. A hardcoded Colors.transparent would vanish.
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final size in FluentAvatarSize.values) {
        await pump(
          tester,
          FluentAvatar(key: key, size: size, initials: 'AL'),
          theme: theme,
        );
        final border = decorationOf(tester).border!.top;
        expect(border.width, greaterThan(0), reason: '${size.name}: width');
        expect(
          border.color.a,
          1.0,
          reason: '${size.name}: the transparent token turns opaque',
        );
      }
    });

    testWidgets('high contrast keeps the activity ring visible', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentAvatar(
          key: key,
          active: FluentAvatarActive.active,
          initials: 'AL',
        ),
        theme: theme,
      );
      await tester.pumpAndSettle();
      final ring = ringOf(tester);
      expect(ring.color!.a, 1.0);
      expect(ring.gapColor!.a, 1.0);
      expect(ring.color, isNot(ring.gapColor));
    });
  });

  group('behaviour', () {
    test('there is no disabled state to render', () {
      // Not a gap in the port: the Figma set has no `State` axis at all — only
      // Type and Size — and upstream ships no disabled rule either. A greyed
      // avatar is a treatment this component may not invent.
      expect(spec.properties.keys, <String>['Type', 'Size']);
    });

    testWidgets('it is non-interactive', (tester) async {
      await pump(tester, const FluentAvatar(key: key, initials: 'AL'));
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
        reason: 'an avatar never takes hover, press or focus of its own',
      );
    });

    testWidgets('the name is announced as an image', (tester) async {
      await pump(
        tester,
        const FluentAvatar(key: key, initials: 'AL', name: 'Ada Lovelace'),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Ada Lovelace', isImage: true),
      );
    });

    testWidgets('a presence badge is anchored to the bottom-right corner', (
      tester,
    ) async {
      // Figma's `Presence Badge` instance sits flush with the avatar's bottom
      // right at every size, and its diameter follows the avatar's: 6, 10, 12,
      // 16, 20, 28.
      const expected = <FluentAvatarSize, double>{
        FluentAvatarSize.size16: 6,
        FluentAvatarSize.size32: 10,
        FluentAvatarSize.size40: 12,
        FluentAvatarSize.size48: 16,
        FluentAvatarSize.size64: 20,
        FluentAvatarSize.size120: 28,
      };

      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentAvatar(
            key: key,
            size: entry.key,
            initials: 'AL',
            status: FluentPresenceStatus.available,
          ),
        );
        final badge = find.byType(FluentPresenceBadge);
        expect(
          tester.getSize(badge).width,
          entry.value,
          reason: '${entry.key.name}: badge diameter',
        );
        final avatar = tester.getRect(find.byKey(key));
        expect(tester.getRect(badge).bottomRight, avatar.bottomRight);
      }
    });
  });
}

/// A provider that never resolves, so no network or asset is touched. The tests
/// only assert that the decoration carries it.
@immutable
class _StubImage extends ImageProvider<_StubImage> {
  const _StubImage();

  @override
  Future<_StubImage> obtainKey(ImageConfiguration configuration) async => this;

  @override
  ImageStreamCompleter loadImage(_StubImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);

  @override
  bool operator ==(Object other) => other is _StubImage;

  @override
  int get hashCode => (_StubImage).hashCode;
}
