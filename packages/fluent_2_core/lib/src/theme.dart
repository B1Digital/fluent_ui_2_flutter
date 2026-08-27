import 'package:fluent_2_fonts/fluent_2_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'tokens/alias_colors.dart';
import 'tokens/color_token.dart';
import 'tokens/elevation.dart';
import 'tokens/global_colors.dart';
import 'tokens/theme_variants.dart';
import 'tokens/typography.dart';

/// A resolved Fluent theme: the alias color layer plus a type ramp.
///
/// The global token layers (spacing, radius, stroke, motion) are compile-time
/// constants and deliberately not carried here — they never vary per theme, so
/// putting them on the theme would only add indirection.
@immutable
class FluentThemeData {
  /// Creates a theme from a colour layer and a type ramp.
  const FluentThemeData({required this.colors, required this.typography});

  /// [typography] defaults to the ramp matching [platform], falling back to
  /// [defaultTargetPlatform].
  factory FluentThemeData.from({
    Brightness brightness = Brightness.light,
    FluentBrandRamp brand = FluentBrandRamp.web,
    FluentTypography? typography,
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  }) {
    assert(
      fontPlatform == null || platform == null,
      'Pass fontPlatform or platform, not both.',
    );
    final colors = FluentColors(brightness: brightness, brand: brand);
    final ramp =
        typography ?? _rampFor(fontPlatform ?? _fontPlatformFor(platform));
    return FluentThemeData(
      colors: colors,
      typography: ramp.withColor(colors.neutralForeground1),
    );
  }

  /// The light theme.
  factory FluentThemeData.light({
    FluentBrandRamp brand = FluentBrandRamp.web,
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  }) => FluentThemeData.from(
    brand: brand,
    fontPlatform: fontPlatform,
    platform: platform,
  );

  /// The dark theme.
  factory FluentThemeData.dark({
    FluentBrandRamp brand = FluentBrandRamp.web,
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  }) => FluentThemeData.from(
    brightness: Brightness.dark,
    brand: brand,
    fontPlatform: fontPlatform,
    platform: platform,
  );

  /// Teams dark, which upstream generates from its own table rather than from
  /// [FluentThemeData.dark] with the Teams ramp.
  factory FluentThemeData.teamsDark({
    FluentBrandRamp brand = FluentBrandRamp.teams,
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  }) => FluentThemeData._withColors(
    FluentTeamsDarkColors(brand: brand),
    fontPlatform,
    platform,
  );

  /// High contrast. Ignores any brand ramp — high contrast has no brand color,
  /// and interactive state is signalled by swapping to the system highlight
  /// rather than by shading.
  factory FluentThemeData.highContrast({
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  }) => FluentThemeData._withColors(
    const FluentHighContrastColors(),
    fontPlatform,
    platform,
  );

  factory FluentThemeData._withColors(
    FluentColors colors,
    FluentFontPlatform? fontPlatform,
    TargetPlatform? platform,
  ) {
    assert(
      fontPlatform == null || platform == null,
      'Pass fontPlatform or platform, not both.',
    );
    final ramp = _rampFor(fontPlatform ?? _fontPlatformFor(platform));
    return FluentThemeData(
      colors: colors,
      typography: ramp.withColor(colors.neutralForeground1),
    );
  }

  static FluentFontPlatform _fontPlatformFor(TargetPlatform? platform) {
    if (platform == null) return FluentFonts.currentPlatform;
    return switch (platform) {
      TargetPlatform.windows => FluentFontPlatform.windows,
      TargetPlatform.macOS => FluentFontPlatform.macOS,
      TargetPlatform.iOS => FluentFontPlatform.iOS,
      TargetPlatform.android ||
      TargetPlatform.fuchsia => FluentFontPlatform.android,
      TargetPlatform.linux => FluentFontPlatform.linux,
    };
  }

  static FluentTypography _rampFor(FluentFontPlatform platform) =>
      switch (platform) {
        FluentFontPlatform.web => FluentTypography.web(),
        FluentFontPlatform.windows => FluentTypography.windows(),
        FluentFontPlatform.macOS => FluentTypography.macOS(),
        FluentFontPlatform.iOS => FluentTypography.ios(),
        FluentFontPlatform.android => FluentTypography.android(),
        FluentFontPlatform.linux => FluentTypography.linux(),
      };

  /// The resolved alias colour layer.
  final FluentColors colors;

  /// The type ramp, already painted with the foreground colour.
  final FluentTypography typography;

  /// This theme's brightness, taken from [colors].
  Brightness get brightness => colors.brightness;

  /// Neutral elevation shadows, resolved for this theme's brightness.
  List<BoxShadow> shadow(FluentElevation level) => level.shadows(
    ambient: colors.neutralShadowAmbient,
    key: colors.neutralShadowKey,
  );

  /// Elevation shadows for surfaces sitting on brand color, which need heavier
  /// opacity to read as the same height.
  List<BoxShadow> brandShadow(FluentElevation level) => level.shadows(
    ambient: colors.brandShadowAmbient,
    key: colors.brandShadowKey,
  );

  /// This theme with the given parts replaced.
  FluentThemeData copyWith({
    FluentColors? colors,
    FluentTypography? typography,
  }) => FluentThemeData(
    colors: colors ?? this.colors,
    typography: typography ?? this.typography,
  );

  @override
  bool operator ==(Object other) =>
      other is FluentThemeData &&
      other.colors == colors &&
      other.typography == typography;

  @override
  int get hashCode => Object.hash(colors, typography);
}

/// Provides a [FluentThemeData] to the subtree. The Fluent counterpart of
/// `Theme`, with no Material dependency.
///
/// Extends [InheritedTheme] so the theme crosses route boundaries and reaches
/// overlays — dialogs and popovers build outside the widget's own subtree and
/// would otherwise lose it.
class FluentTheme extends InheritedTheme {
  /// Provides [data] to [child].
  const FluentTheme({super.key, required this.data, required super.child});

  /// The theme supplied to the subtree.
  final FluentThemeData data;

  /// The nearest theme, or a light default if there is none.
  ///
  /// Never returns null so widgets stay usable under a bare `runApp` and in
  /// widget tests without a [FluentTheme] ancestor.
  static FluentThemeData of(BuildContext context) =>
      maybeOf(context) ?? FluentThemeData.light();

  /// The nearest theme, or null when there is no ancestor.
  static FluentThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTheme>()?.data;

  @override
  bool updateShouldNotify(FluentTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTheme(data: data, child: child);
}

/// Overrides individual theme tokens for a subtree.
///
/// The counterpart of nesting a `FluentProvider` with a `PartialTheme` in Fluent
/// React: overrides shallow-merge over whatever the ancestor theme resolved, so
/// untouched tokens keep following the base palette, brand ramp and brightness.
///
/// ```dart
/// FluentThemeOverride(
///   colors: {FluentColorToken.brandBackground: Color(0xFF780510)},
///   child: FluentButton(...),
/// )
/// ```
///
/// Nesting is supported and the innermost override wins per token.
class FluentThemeOverride extends StatelessWidget {
  /// Overrides [colors] tokens, and optionally swaps the type ramp, for [child].
  const FluentThemeOverride({
    super.key,
    this.colors = const {},
    this.typography,
    required this.child,
  });

  /// Tokens to override. Keys absent here keep their computed value.
  final Map<FluentColorToken, Color> colors;

  /// Replaces the type ramp outright. Overriding
  /// [FluentColorToken.neutralForeground1] alone already re-paints the existing
  /// ramp, so this is only needed to change metrics.
  final FluentTypography? typography;

  /// The subtree the overrides apply to.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The early return comes first: reading the theme before it would register
    // a dependency on every ancestor theme change for an override that does
    // nothing, rebuilding the whole subtree for free.
    if (colors.isEmpty && typography == null) return child;
    final base = FluentTheme.of(context);

    final palette = colors.isEmpty
        ? base.colors
        : base.colors.withOverrides(colors);

    // The type ramp is pre-painted with neutralForeground1 at construction, so
    // overriding that token would otherwise leave every text style on the old
    // colour. Upstream has no such trap — there text resolves the CSS variable
    // at paint time.
    var ramp = typography ?? base.typography;
    if (typography == null &&
        colors.containsKey(FluentColorToken.neutralForeground1)) {
      ramp = ramp.withColor(palette.neutralForeground1);
    }

    return FluentTheme(
      data: base.copyWith(colors: palette, typography: ramp),
      child: child,
    );
  }
}
