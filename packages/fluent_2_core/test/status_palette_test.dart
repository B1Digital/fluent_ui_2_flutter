import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expected values are read off `tool/figma_tokens.json`, which is the resolved
/// extraction from the official Fluent 2 Figma file. They are asserted here
/// rather than trusted because `tool/generate_tokens.py` is what produced the
/// Dart, and a generator bug would otherwise be invisible.
void main() {
  group('status colors (alias layer)', () {
    const light = FluentColors();
    const dark = FluentColors(brightness: Brightness.dark);

    test('resolve per brightness where the token differs', () {
      // Figma Status/Success/Foreground/1/Rest
      expect(light.statusSuccessForeground1, const Color(0xFF0E700E));
      expect(dark.statusSuccessForeground1, const Color(0xFF54B054));

      // Figma Status/Warning/Background/1/Rest
      expect(light.statusWarningBackground1, const Color(0xFFFFF9F5));
      expect(dark.statusWarningBackground1, const Color(0xFF4A1E04));
    });

    test('are brightness-independent where upstream defines one value', () {
      // Danger/Background/3 and the presence states are identical in both
      // themes upstream — a port that "helpfully" darkened them would be wrong.
      expect(light.statusDangerBackground3, const Color(0xFFC50F1F));
      expect(dark.statusDangerBackground3, light.statusDangerBackground3);

      expect(light.statusAvailableForeground3, const Color(0xFF13A10E));
      expect(dark.statusAvailableForeground3, light.statusAvailableForeground3);
    });

    test('never leak transparency', () {
      // Status colours are opaque surfaces; an alpha here means a bad extraction.
      expect(light.statusDangerBackground1.a, 1.0);
      expect(dark.statusSevereForeground1.a, 1.0);
    });
  });

  group('palette colors', () {
    const light = FluentPaletteColors();
    const dark = FluentPaletteColors(brightness: Brightness.dark);

    test('cover all 35 families for the three universal tokens', () {
      expect(FluentPaletteFamily.values.length, 35);
      for (final f in FluentPaletteFamily.values) {
        expect(light.background2Rest(f), isA<Color>(), reason: f.name);
        expect(light.foreground2Rest(f), isA<Color>(), reason: f.name);
        expect(light.strokeActiveRest(f), isA<Color>(), reason: f.name);
      }
    });

    test('resolve to the extracted values', () {
      expect(
        light.background2Rest(FluentPaletteFamily.cranberry),
        const Color(0xFFEEACB2),
      );
      expect(
        dark.background2Rest(FluentPaletteFamily.cranberry),
        const Color(0xFF6E0811),
      );
      expect(
        light.strokeActiveRest(FluentPaletteFamily.anchor),
        const Color(0xFF394146),
      );
    });

    test('extended tokens exist only for the seven extended families', () {
      const extended = {
        FluentPaletteFamily.berry,
        FluentPaletteFamily.darkOrange,
        FluentPaletteFamily.green,
        FluentPaletteFamily.lightGreen,
        FluentPaletteFamily.marigold,
        FluentPaletteFamily.red,
        FluentPaletteFamily.yellow,
      };
      for (final f in FluentPaletteFamily.values) {
        final value = light.foreground1Rest(f);
        if (extended.contains(f)) {
          expect(value, isNotNull, reason: '${f.name} should define it');
        } else {
          // null, not a substituted fallback — upstream simply has no such token.
          expect(value, isNull, reason: '${f.name} should not define it');
        }
      }
      expect(
        light.foreground1Rest(FluentPaletteFamily.red),
        const Color(0xFFBC2F32),
      );
    });
  });

  group('shared ramps', () {
    test('are complete: 49 families, 12 stops each', () {
      expect(FluentSharedColor.values.length, 49);
      expect(FluentSharedRamp.all.length, 49);
      for (final f in FluentSharedColor.values) {
        expect(FluentSharedRamp.all.containsKey(f), isTrue, reason: f.name);
      }
    });

    test('carry the canonical Fluent values', () {
      expect(
        FluentSharedRamp.of(FluentSharedColor.red).primary,
        const Color(0xFFD13438),
      );
      expect(
        FluentSharedRamp.of(FluentSharedColor.cranberry).tint40,
        const Color(0xFFEEACB2),
      );
    });

    test('run dark to light across the twelve stops', () {
      for (final f in FluentSharedColor.values) {
        final r = FluentSharedRamp.of(f);
        expect(
          r.shade50.computeLuminance(),
          lessThan(r.primary.computeLuminance()),
          reason: '${f.name}: shade50 must be darker than primary',
        );
        expect(
          r.tint60.computeLuminance(),
          greaterThan(r.primary.computeLuminance()),
          reason: '${f.name}: tint60 must be lighter than primary',
        );
      }
    });
  });

  group('acrylic material', () {
    const light = FluentAcrylic();
    const dark = FluentAcrylic(brightness: Brightness.dark);

    test('backgrounds are translucent — that is the whole point', () {
      expect(light.backgroundPrimary.a, lessThan(1.0));
      expect(dark.backgroundPrimary.a, lessThan(1.0));
      expect(light.backgroundPrimary, const Color(0x80FFFFFF));
    });

    test('blur is the same sigma in both themes', () {
      expect(light.backgroundBlur, 60.0);
      expect(dark.backgroundBlur, 60.0);
    });

    test('dark stroke stop 2 is opaque, unlike its siblings', () {
      // Verbatim from Figma: the other stops are 0x33 alpha in both themes but
      // this one is a solid #2c3136 in dark. Asserted so a future "cleanup"
      // that regularises it fails loudly.
      expect(dark.strokeStop2.a, 1.0);
      expect(dark.strokeStop1.a, lessThan(1.0));
      expect(dark.strokeStop3.a, lessThan(1.0));
    });
  });

  group('theme wiring', () {
    test('surfaces status, palette and acrylic off the colors object', () {
      final t = FluentThemeData.light();
      expect(t.colors.statusDangerBackground3, const Color(0xFFC50F1F));
      expect(
        t.colors.palette.background2Rest(FluentPaletteFamily.cranberry),
        const Color(0xFFEEACB2),
      );
      expect(t.colors.acrylic.backgroundBlur, 60.0);
    });

    test('follow the theme brightness', () {
      expect(
        FluentThemeData.dark().colors.statusSuccessForeground1,
        const Color(0xFF54B054),
      );
      expect(
        FluentThemeData.light().colors.statusSuccessForeground1,
        const Color(0xFF0E700E),
      );
    });
  });
  group('high contrast keeps every surface readable', () {
    // Regression: neutralForegroundInverted mapped to `highlightText`, which is
    // canvas's own colour — so it painted black on black over
    // neutralBackgroundInverted. Tooltip, Popover and TeachingPopover all
    // rendered outlined but empty. Nothing failed; the text was simply gone.
    const hc = FluentHighContrastColors();

    /// Foreground/background pairs a component actually paints together.
    const pairs = <(String, String)>[
      ('neutralForegroundInverted', 'neutralBackgroundInverted'),
      ('neutralForegroundInvertedHover', 'neutralBackgroundInverted'),
      ('neutralForegroundInvertedPressed', 'neutralBackgroundInverted'),
      ('neutralForegroundInvertedSelected', 'neutralBackgroundInverted'),
      ('neutralForeground1', 'neutralBackground1'),
      ('neutralForeground2', 'neutralBackground1'),
      ('neutralForegroundOnBrand', 'brandBackground'),
      ('neutralForegroundStaticInverted', 'neutralBackgroundStatic'),
    ];

    test('no foreground collides with the surface it sits on', () {
      for (final (fg, bg) in pairs) {
        final f = hc.resolve(FluentColorToken.values.byName(fg));
        final b = hc.resolve(FluentColorToken.values.byName(bg));
        expect(f, isNot(b), reason: '$fg is invisible on $bg in high contrast');
      }
    });
  });
}
