import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parity target: nesting a `FluentProvider` with a `PartialTheme` in Fluent
/// React overrides one of ~467 theme keys for one subtree, shallow-merged over
/// the ancestor. These assert the Dart equivalent behaves the same way.
void main() {
  const magenta = Color(0xFF780510);

  /// Renders [child] under [theme] and hands back the theme each builder saw.
  Future<FluentThemeData> themeSeenBy(
    WidgetTester tester,
    Widget Function(Widget probe) wrap, {
    FluentThemeData? theme,
  }) async {
    late FluentThemeData seen;
    await tester.pumpWidget(
      FluentTheme(
        data: theme ?? FluentThemeData.light(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: wrap(
            Builder(
              builder: (context) {
                seen = FluentTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    return seen;
  }

  group('single-token override', () {
    testWidgets('applies to the subtree and leaves siblings alone', (
      tester,
    ) async {
      late FluentThemeData inside;
      late FluentThemeData outside;
      await tester.pumpWidget(
        FluentTheme(
          data: FluentThemeData.light(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                FluentThemeOverride(
                  colors: const {FluentColorToken.brandBackground: magenta},
                  child: Builder(
                    builder: (c) {
                      inside = FluentTheme.of(c);
                      return const SizedBox();
                    },
                  ),
                ),
                Builder(
                  builder: (c) {
                    outside = FluentTheme.of(c);
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(inside.colors.brandBackground, magenta);
      expect(outside.colors.brandBackground, isNot(magenta));
    });

    testWidgets('leaves every other token computing from the base palette', (
      tester,
    ) async {
      final base = FluentThemeData.light();
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {FluentColorToken.brandBackground: magenta},
          child: probe,
        ),
      );
      expect(seen.colors.brandBackground, magenta);
      expect(seen.colors.neutralForeground1, base.colors.neutralForeground1);
      expect(seen.colors.neutralBackground1, base.colors.neutralBackground1);
      // Still derives from the brand ramp, not frozen at construction.
      expect(seen.colors.brandForeground1, base.colors.brandForeground1);
    });
  });

  group('nesting', () {
    testWidgets('inner wins per token, outer survives for the rest', (
      tester,
    ) async {
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {
            FluentColorToken.brandBackground: Color(0xFF111111),
            FluentColorToken.neutralBackground1: Color(0xFF222222),
          },
          child: FluentThemeOverride(
            colors: const {FluentColorToken.brandBackground: Color(0xFF333333)},
            child: probe,
          ),
        ),
      );
      expect(seen.colors.brandBackground, const Color(0xFF333333));
      expect(seen.colors.neutralBackground1, const Color(0xFF222222));
    });
  });

  group('variant themes', () {
    testWidgets('override does not demote high contrast to the base palette', (
      tester,
    ) async {
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {FluentColorToken.brandBackground: magenta},
          child: probe,
        ),
        theme: FluentThemeData.highContrast(),
      );
      expect(
        seen.colors,
        isA<FluentHighContrastColors>(),
        reason: 'withOverrides must preserve the concrete variant',
      );
      expect(seen.colors.brandBackground, magenta);
      // A high-contrast token untouched by the override still collapses onto
      // the system colour rather than the default palette's value.
      expect(
        seen.colors.neutralForeground1,
        FluentThemeData.highContrast().colors.neutralForeground1,
      );
    });

    testWidgets('override preserves Teams dark and its brand ramp', (
      tester,
    ) async {
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {FluentColorToken.neutralBackground1: magenta},
          child: probe,
        ),
        theme: FluentThemeData.teamsDark(),
      );
      expect(seen.colors, isA<FluentTeamsDarkColors>());
      expect(seen.colors.neutralBackground1, magenta);
      expect(seen.colors.brand, FluentBrandRamp.teams);
    });
  });

  group('typography coupling', () {
    testWidgets('overriding neutralForeground1 re-paints the type ramp', (
      tester,
    ) async {
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {FluentColorToken.neutralForeground1: magenta},
          child: probe,
        ),
      );
      expect(seen.colors.neutralForeground1, magenta);
      // The ramp is pre-painted at construction; without the re-paint every
      // text style would silently keep the old foreground.
      expect(seen.typography.body1.color, magenta);
      expect(seen.typography.caption1.color, magenta);
    });

    testWidgets('overriding an unrelated token leaves the ramp alone', (
      tester,
    ) async {
      final base = FluentThemeData.light();
      final seen = await themeSeenBy(
        tester,
        (probe) => FluentThemeOverride(
          colors: const {FluentColorToken.brandBackground: magenta},
          child: probe,
        ),
      );
      expect(seen.typography.body1.color, base.typography.body1.color);
    });
  });

  group('token identity', () {
    test('every enum value resolves', () {
      const colors = FluentColors();
      for (final t in FluentColorToken.values) {
        expect(colors.resolve(t), isA<Color>(), reason: t.name);
      }
      expect(FluentColorToken.values.length, 228);
    });

    test('resolve honours an override', () {
      const colors = FluentColors();
      final overridden = colors.withOverrides({
        FluentColorToken.brandBackground: magenta,
      });
      expect(overridden.resolve(FluentColorToken.brandBackground), magenta);
      expect(colors.resolve(FluentColorToken.brandBackground), isNot(magenta));
    });
  });

  group('theme equality is structural', () {
    // Regression: FluentTypography was @immutable but had no ==, so two
    // separately built ramps were never equal. That made FluentThemeData ==
    // always false and FluentTheme.updateShouldNotify always true, rebuilding
    // every theme dependent on any ancestor rebuild.
    test('two identically built type ramps are equal', () {
      expect(FluentTypography.web(), FluentTypography.web());
      expect(FluentTypography.web().hashCode, FluentTypography.web().hashCode);
      expect(FluentTypography.web(), isNot(FluentTypography.android()));
    });

    test('two identically built themes are equal', () {
      expect(
        FluentThemeData.light(platform: TargetPlatform.windows),
        FluentThemeData.light(platform: TargetPlatform.windows),
      );
      expect(
        FluentThemeData.light(platform: TargetPlatform.windows),
        isNot(FluentThemeData.dark(platform: TargetPlatform.windows)),
      );
    });
  });

  group('equality', () {
    test('palettes differing only in overrides are not equal', () {
      const base = FluentColors();
      final a = base.withOverrides({FluentColorToken.brandBackground: magenta});
      final b = base.withOverrides({
        FluentColorToken.brandBackground: const Color(0xFF000000),
      });
      expect(a, isNot(base));
      expect(a, isNot(b));
    });

    test('identical overrides compare equal, so no needless rebuilds', () {
      const base = FluentColors();
      final a = base.withOverrides({FluentColorToken.brandBackground: magenta});
      final b = base.withOverrides({FluentColorToken.brandBackground: magenta});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('updateShouldNotify tracks the overrides', () {
      // This is the mechanism that decides whether dependents rebuild. Testing
      // it directly rather than through pumpWidget, because pumping a freshly
      // built tree rebuilds children structurally no matter what this returns.
      FluentTheme themeWith(Color brand) => FluentTheme(
        data: FluentThemeData.light().copyWith(
          colors: const FluentColors().withOverrides({
            FluentColorToken.brandBackground: brand,
          }),
        ),
        child: const SizedBox(),
      );

      expect(
        themeWith(magenta).updateShouldNotify(themeWith(magenta)),
        isFalse,
        reason: 'equal overrides must not rebuild the subtree every frame',
      );
      expect(
        themeWith(
          magenta,
        ).updateShouldNotify(themeWith(const Color(0xFF000000))),
        isTrue,
        reason: 'a changed override must reach dependents',
      );
    });
  });
}
