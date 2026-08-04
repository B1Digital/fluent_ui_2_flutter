import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brand ramp', () {
    test('indexes by Fluent stop number', () {
      expect(FluentBrandRamp.web[10], const Color(0xFF061724));
      expect(FluentBrandRamp.web[80], const Color(0xFF0F6CBD));
      expect(FluentBrandRamp.web[160], const Color(0xFFEBF3FC));
    });

    test('rejects stops off the ramp', () {
      expect(() => FluentBrandRamp.web[0], throwsA(isA<AssertionError>()));
      expect(() => FluentBrandRamp.web[85], throwsA(isA<AssertionError>()));
      expect(() => FluentBrandRamp.web[170], throwsA(isA<AssertionError>()));
    });
  });

  group('brand generator', () {
    // Golden values captured by executing the upstream TypeScript
    // (theme-designer getBrandTokensFromPalette) on the same key color.
    // If the port drifts, these break.
    const referenceForKeyColor0F6CBD = [
      0xFF00030A,
      0xFF001832,
      0xFF00274B,
      0xFF00335F,
      0xFF003F74,
      0xFF004C8A,
      0xFF005AA0,
      0xFF0067B7,
      0xFF2675C6,
      0xFF4182D2,
      0xFF5A90DC,
      0xFF719EE4,
      0xFF87ACEB,
      0xFF9DBBF1,
      0xFFB3CAF6,
      0xFFC9D8F9,
    ];

    test('matches the upstream algorithm exactly', () {
      final shades = FluentBrandGenerator.shades(const Color(0xFF0F6CBD));
      expect(
        shades.map((c) => c.toARGB32()).toList(),
        referenceForKeyColor0F6CBD,
      );
    });

    test('does NOT reproduce the hand-authored web ramp', () {
      // Documents a real divergence rather than papering over it: the shipped
      // ramp is authored, not generated, and stop 80 is the key color there
      // but not here.
      final generated = FluentBrandRamp.fromKeyColor(const Color(0xFF0F6CBD));
      expect(generated[80], isNot(FluentBrandRamp.web[80]));
      expect(generated[80], isNot(const Color(0xFF0F6CBD)));
    });

    test('produces 16 stops addressable by Fluent stop number', () {
      final ramp = FluentBrandRamp.fromKeyColor(const Color(0xFFD13438));
      expect(ramp[10], isA<Color>());
      expect(ramp[160], isA<Color>());
      expect(ramp[10], isNot(ramp[160]));
    });

    test('ramp runs dark to light', () {
      final ramp = FluentBrandRamp.fromKeyColor(const Color(0xFF107C10));
      double lum(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
      for (var stop = 10; stop < 160; stop += 10) {
        expect(
          lum(ramp[stop]),
          lessThanOrEqualTo(lum(ramp[stop + 10]) + 1e-9),
          reason: 'stop $stop should not be lighter than ${stop + 10}',
        );
      }
    });

    test('every generated shade is inside the sRGB gamut', () {
      for (final key in [0xFF0F6CBD, 0xFFD13438, 0xFF107C10, 0xFFFDE300]) {
        for (final shade in FluentBrandGenerator.shades(Color(key))) {
          final argb = shade.toARGB32();
          for (final c in [
            (argb >> 16) & 0xFF,
            (argb >> 8) & 0xFF,
            argb & 0xFF,
          ]) {
            expect(c, inInclusiveRange(0, 255));
          }
        }
      }
    });

    test('hue torsion changes the ramp', () {
      final straight = FluentBrandGenerator.shades(const Color(0xFF0F6CBD));
      final twisted = FluentBrandGenerator.shades(
        const Color(0xFF0F6CBD),
        hueTorsion: 0.5,
      );
      expect(straight, isNot(twisted));
    });

    test('vibrancy changes the ramp', () {
      final base = FluentBrandGenerator.shades(const Color(0xFF0F6CBD));
      final vivid = FluentBrandGenerator.shades(
        const Color(0xFF0F6CBD),
        vibrancy: 0.9,
      );
      expect(base, isNot(vivid));
    });
  });

  group('theme variants', () {
    test(
      'Teams dark differs from plain dark in exactly the documented tokens',
      () {
        const plain = FluentColors(
          brightness: Brightness.dark,
          brand: FluentBrandRamp.teams,
        );
        const teams = FluentTeamsDarkColors();
        // Layered backgrounds shift one step lighter.
        expect(plain.neutralBackground2, const Color(0xFF1F1F1F));
        expect(teams.neutralBackground2, const Color(0xFF242424));
        expect(teams.neutralBackground5, const Color(0xFF0A0A0A));
        // Untouched tokens fall through.
        expect(teams.neutralBackground1, plain.neutralBackground1);
        expect(teams.neutralForeground1, plain.neutralForeground1);
      },
    );

    test('high contrast collapses onto system colors', () {
      const hc = FluentHighContrastColors();
      expect(hc.neutralBackground1, FluentHighContrast.canvas);
      expect(hc.neutralForeground1, FluentHighContrast.canvasText);
      expect(hc.brandForegroundLink, FluentHighContrast.hyperlink);
      expect(hc.neutralBackground1Hover, FluentHighContrast.highlight);
    });

    test('high contrast makes transparent borders visible', () {
      const normal = FluentColors();
      const hc = FluentHighContrastColors();
      expect(normal.transparentStroke.a, 0);
      expect(hc.transparentStroke, FluentHighContrast.canvasText);
      expect(hc.transparentBackgroundHover, FluentHighContrast.highlight);
    });
  });

  group('alias colors', () {
    test('resolve differently per brightness', () {
      const light = FluentColors();
      const dark = FluentColors(brightness: Brightness.dark);
      expect(light.neutralBackground1, const Color(0xFFFFFFFF));
      expect(dark.neutralBackground1, const Color(0xFF292929));
      expect(light.neutralForeground1, const Color(0xFF242424));
      expect(dark.neutralForeground1, const Color(0xFFFFFFFF));
    });

    test('focus ring inverts so it stays visible on both themes', () {
      const light = FluentColors();
      const dark = FluentColors(brightness: Brightness.dark);
      expect(light.strokeFocus1, isNot(light.strokeFocus2));
      expect(light.strokeFocus1, dark.strokeFocus2);
      expect(light.strokeFocus2, dark.strokeFocus1);
    });

    test('follow the brand ramp they were given', () {
      const web = FluentColors();
      const classic = FluentColors(brand: FluentBrandRamp.communicationBlue);
      expect(web.brandBackground, const Color(0xFF0F6CBD));
      expect(classic.brandBackground, const Color(0xFF0078D4));
    });

    test('are overridable by subclassing', () {
      expect(const _Rebranded().brandBackground, const Color(0xFFFF0000));
      // Untouched tokens still resolve normally.
      expect(const _Rebranded().neutralBackground1, const Color(0xFFFFFFFF));
    });
  });

  group('elevation', () {
    test('builds an ambient layer at zero offset and an offset key layer', () {
      final shadows = FluentThemeData.light().shadow(FluentElevation.shadow16);
      expect(shadows, hasLength(2));
      expect(shadows[0].offset, Offset.zero);
      expect(shadows[0].blurRadius, 2);
      expect(shadows[1].offset, const Offset(0, 8));
      expect(shadows[1].blurRadius, 16);
    });

    test('dark shadows are heavier than light', () {
      final light = FluentThemeData.light().shadow(FluentElevation.shadow8);
      final dark = FluentThemeData.dark().shadow(FluentElevation.shadow8);
      expect(dark[0].color.a, greaterThan(light[0].color.a));
    });

    test('luminosity model gives darker surfaces stronger shadows', () {
      const white = Color(0xFFFFFFFF);
      const black = Color(0xFF000000);
      expect(
        FluentShadowLuminosity.ambientOpacity(black),
        greaterThan(FluentShadowLuminosity.ambientOpacity(white)),
      );
      // 42 - 0.116 * 255 = 12.42 -> 12%
      expect(FluentShadowLuminosity.ambientOpacity(white), closeTo(0.12, 1e-9));
      expect(FluentShadowLuminosity.keyOpacity(white), closeTo(0.11, 1e-9));
    });
  });

  group('typography', () {
    test('web uses the bundled open-source Selawik family', () {
      final t = FluentTypography.web();
      expect(FluentFontFamily.base, 'Selawik');
      expect(t.body1.fontFamily, 'Selawik');
      expect(FluentFontFamily.baseFallback, isNot(contains('Segoe UI')));
    });

    test('exposes the font facade through core', () {
      expect(FluentFonts.familiesFor(FluentFontPlatform.web).text, 'Selawik');
      expect(
        FluentFonts.familiesFor(FluentFontPlatform.windows).text,
        'Selawik',
      );
      expect(FluentFonts.requiresLoadingFor(FluentFontPlatform.web), isTrue);
      expect(
        FluentFonts.requiresLoadingFor(FluentFontPlatform.android),
        isFalse,
      );
    });

    test('web subtitle1 follows the Fluent Web 20/26 metric', () {
      final t = FluentTypography.web();
      expect(t.subtitle1.fontSize, 20);
      expect(t.subtitle1.height! * t.subtitle1.fontSize!, 26);
    });

    test('platform ramps use their published body and display metrics', () {
      double lineHeight(TextStyle style) => style.height! * style.fontSize!;

      final web = FluentTypography.web();
      final windows = FluentTypography.windows();
      final macOS = FluentTypography.macOS();
      final iOS = FluentTypography.ios();
      final android = FluentTypography.android();

      expect((web.body1.fontSize, lineHeight(web.body1)), (14, 20));
      expect((windows.body2.fontSize, lineHeight(windows.body2)), (18, 24));
      expect((macOS.body1.fontSize, lineHeight(macOS.body1)), (13, 16));
      expect((iOS.body1.fontSize, lineHeight(iOS.body1)), (17, 22));
      expect((android.body1.fontSize, lineHeight(android.body1)), (16, 24));

      expect((web.display.fontSize, lineHeight(web.display)), (68, 92));
      expect((windows.display.fontSize, lineHeight(windows.display)), (68, 92));
      expect((macOS.display.fontSize, lineHeight(macOS.display)), (30, 40));
      expect((iOS.display.fontSize, lineHeight(iOS.display)), (60, 70));
      expect((android.display.fontSize, lineHeight(android.display)), (60, 72));
    });

    test('theme paints the ramp with the foreground token', () {
      final theme = FluentThemeData.dark(platform: TargetPlatform.windows);
      expect(theme.typography.body1.color, theme.colors.neutralForeground1);
      expect(theme.typography.display.color, const Color(0xFFFFFFFF));
    });

    test('fontPlatform can explicitly select the Web ramp', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(theme.typography.caption2.fontSize, 10);
      expect(theme.typography.subtitle1.fontSize, 20);
      expect(theme.typography.subtitle1.height, 26 / 20);
    });
  });

  group('breakpoints', () {
    test('map width to the containing size class', () {
      expect(FluentBreakpoint.of(400), FluentBreakpoint.small);
      expect(FluentBreakpoint.of(479), FluentBreakpoint.small);
      expect(FluentBreakpoint.of(480), FluentBreakpoint.medium);
      expect(FluentBreakpoint.of(1024), FluentBreakpoint.xLarge);
      expect(FluentBreakpoint.of(5000), FluentBreakpoint.xxxLarge);
    });
  });

  group('FluentTheme', () {
    testWidgets('reaches descendants', (tester) async {
      late FluentThemeData seen;
      final theme = FluentThemeData.dark(platform: TargetPlatform.windows);
      await tester.pumpWidget(
        FluentTheme(
          data: theme,
          child: Builder(
            builder: (context) {
              seen = FluentTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, theme);
    });

    testWidgets('falls back to light with no ancestor', (tester) async {
      late Brightness seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = FluentTheme.of(context).brightness;
            return const SizedBox();
          },
        ),
      );
      expect(seen, Brightness.light);
    });

    testWidgets('FluentApp provides theme and default text style', (
      tester,
    ) async {
      late FluentThemeData seen;
      late TextStyle text;
      await tester.pumpWidget(
        FluentApp(
          themeMode: FluentThemeMode.dark,
          darkTheme: FluentThemeData.dark(platform: TargetPlatform.windows),
          home: Builder(
            builder: (context) {
              seen = FluentTheme.of(context);
              text = DefaultTextStyle.of(context).style;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen.brightness, Brightness.dark);
      expect(text.fontSize, 14);
      expect(text.color, const Color(0xFFFFFFFF));
    });
  });
}

class _Rebranded extends FluentColors {
  const _Rebranded();

  @override
  Color get brandBackground => const Color(0xFFFF0000);
}
