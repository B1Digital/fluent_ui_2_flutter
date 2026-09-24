import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/theme_variants.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Theme menu's list, against the Fluent addon's (`react-storybook-addon`
/// `theme.ts`, re-read on Storybook 9.1.17): the same seven themes, in the same
/// order, under the same labels, each resolving to the colours the live docs
/// page computes for its story `FluentProvider`.
///
/// Colours are the probe's `themes.*.vars` (fidelity critic, A7 and the theme
/// row of section B): `colorBrandBackground`, `colorNeutralBackground1` and the
/// story wrapper's `colorNeutralBackground2`.
void main() {
  test('exactly upstream seven, in menu order, with upstream labels', () {
    expect(ThemeVariant.values.map((ThemeVariant v) => v.label), <String>[
      'Web Light',
      'Web Dark',
      'Teams Light',
      'Teams Dark',
      'Teams Light V2.1',
      'Teams Dark V2.1',
      'Teams High Contrast',
    ]);
  });

  // (brandBackground, neutralBackground1, neutralBackground2), upstream.
  const Map<ThemeVariant, (Color, Color, Color)> upstream =
      <ThemeVariant, (Color, Color, Color)>{
        ThemeVariant.webLight: (
          Color(0xFF0F6CBD),
          Color(0xFFFFFFFF),
          Color(0xFFFAFAFA),
        ),
        ThemeVariant.webDark: (
          Color(0xFF115EA3),
          Color(0xFF292929),
          Color(0xFF1F1F1F),
        ),
        ThemeVariant.teamsLight: (
          Color(0xFF5B5FC7),
          Color(0xFFFFFFFF),
          Color(0xFFFAFAFA),
        ),
        ThemeVariant.teamsDark: (
          Color(0xFF4F52B2),
          Color(0xFF292929),
          Color(0xFF242424),
        ),
        ThemeVariant.teamsV21Light: (
          Color(0xFF654CF5),
          Color(0xFFFFFFFF),
          Color(0xFFFAFAFA),
        ),
        ThemeVariant.teamsV21Dark: (
          Color(0xFF5A40DB),
          Color(0xFF292929),
          Color(0xFF242424),
        ),
        ThemeVariant.highContrast: (
          Color(0xFFFFFFFF),
          Color(0xFF000000),
          Color(0xFF000000),
        ),
      };

  for (final MapEntry<ThemeVariant, (Color, Color, Color)> row
      in upstream.entries) {
    test('${row.key.label} resolves to upstream colours', () {
      final FluentColors colors = row.key.data.colors;
      final (Color brand, Color nb1, Color nb2) = row.value;
      expect(colors.brandBackground, brand, reason: 'brandBackground');
      expect(colors.neutralBackground1, nb1, reason: 'neutralBackground1');
      expect(colors.neutralBackground2, nb2, reason: 'neutralBackground2');
    });
  }
}
