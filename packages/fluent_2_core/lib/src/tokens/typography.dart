// ignore_for_file: public_member_api_docs
// Each member below is a single stop on a named numeric scale — the
// identifier and its value are the documentation (`size20 = 2`,
// `ultraFast = 50ms`). The class doc explains the scale; per-stop prose
// would restate the name and nothing more. Real API elsewhere is covered.
import 'package:fluent_2_fonts/fluent_2_fonts.dart';
import 'package:flutter/widgets.dart';

/// Global font-size ramp (px). Source: `global/fonts.ts`.
///
/// The ramp deliberately has gaps — there is no Base700/800/900 and no
/// Hero100–600. Don't fill them in.
abstract final class FluentFontSize {
  static const double base100 = 10;
  static const double base200 = 12;
  static const double base300 = 14;
  static const double base400 = 16;
  static const double base500 = 20;
  static const double base600 = 24;
  static const double hero700 = 28;
  static const double hero800 = 32;
  static const double hero900 = 40;
  static const double hero1000 = 68;
}

/// Global line-height ramp (px). Source: `global/fonts.ts`.
abstract final class FluentLineHeight {
  static const double base100 = 14;
  static const double base200 = 16;
  static const double base300 = 20;
  static const double base400 = 22;
  static const double base500 = 28;
  static const double base600 = 32;
  static const double hero700 = 36;
  static const double hero800 = 40;
  static const double hero900 = 52;
  static const double hero1000 = 92;
}

abstract final class FluentFontWeight {
  static const FontWeight regular = FontWeight.w400;

  /// Defined upstream but used by zero web ramp styles. Android uses it.
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// Font family stacks based on `global/fonts.ts`.
///
/// Fluent specifies Segoe UI on Web and Segoe UI Variable on Windows. Both use
/// the dynamically loaded, open-source Selawik substitute. Apple and Android
/// ramps use their native system families.
abstract final class FluentFontFamily {
  static const String base = 'Selawik';
  static const List<String> baseFallback = [
    '-apple-system',
    'BlinkMacSystemFont',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  static const String monospace = 'Consolas';
  static const List<String> monospaceFallback = [
    'Courier New',
    'Courier',
    'monospace',
  ];

  /// Tabular figures. Bahnschrift first, then the base stack.
  static const String numeric = 'Bahnschrift';
  static const List<String> numericFallback = [base, ...baseFallback];
}

/// The Fluent 2 type ramp.
///
/// Ramps differ per platform. Web and Windows use separate Selawik-backed
/// ramps, macOS and iOS use their distinct San Francisco ramps, and Android
/// uses its Roboto ramp. Pick the one matching the surface being built.
@immutable
class FluentTypography {
  const FluentTypography({
    required this.caption2,
    required this.caption2Strong,
    required this.caption1,
    required this.caption1Strong,
    required this.caption1Stronger,
    required this.body1,
    required this.body1Strong,
    required this.body1Stronger,
    required this.body2,
    required this.body2Strong,
    required this.subtitle2,
    required this.subtitle2Stronger,
    required this.subtitle1,
    required this.title3,
    required this.title2,
    required this.title1,
    required this.largeTitle,
    required this.display,
  });

  /// The Web ramp (Selawik). Sizes are logical pixels.
  ///
  /// `body2Strong` does not exist upstream on web; it is aliased to
  /// [subtitle2], which has identical metrics with semibold weight.
  factory FluentTypography.web({Color? color}) =>
      FluentTypography._webLike(FluentFontPlatform.web, color);

  /// The Linux fallback uses Web metrics with the native sans-serif family.
  /// Fluent publishes no dedicated Linux ramp.
  factory FluentTypography.linux({Color? color}) =>
      FluentTypography._webLike(FluentFontPlatform.linux, color);

  static FluentTypography _webLike(FluentFontPlatform platform, Color? color) {
    final family = FluentFonts.familiesFor(platform).text;
    TextStyle s(double size, double lineHeight, FontWeight weight) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: FluentFontFamily.baseFallback,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
    const r = FluentFontWeight.regular;
    const sb = FluentFontWeight.semibold;
    const b = FluentFontWeight.bold;

    final subtitle2 = s(16, 22, sb);
    return FluentTypography(
      caption2: s(10, 14, r),
      caption2Strong: s(10, 14, sb),
      caption1: s(12, 16, r),
      caption1Strong: s(12, 16, sb),
      caption1Stronger: s(12, 16, b),
      body1: s(14, 20, r),
      body1Strong: s(14, 20, sb),
      body1Stronger: s(14, 20, b),
      body2: s(16, 22, r),
      body2Strong: subtitle2,
      subtitle2: subtitle2,
      subtitle2Stronger: s(16, 22, b),
      // 26, per https://fluent2.microsoft.design/typography — the published
      // ramp is the authority here, not the shipped TypeScript.
      // `typographyStyles.subtitle1` binds `lineHeightBase500`, which
      // `global/fonts.ts` sets to 28px, so React renders this 2px taller than
      // the design system documents. Figma's component frames were drawn
      // against the 28 line box, which is why Dialog, Accordion, Avatar,
      // Spinner and Drawer all have to state the 2px themselves.
      subtitle1: s(20, 26, sb),
      title3: s(24, 32, sb),
      title2: s(28, 36, sb),
      title1: s(32, 40, sb),
      largeTitle: s(40, 52, sb),
      display: s(68, 92, sb),
    );
  }

  /// The native Windows ramp (Selawik substituting for Segoe UI Variable).
  /// Sizes are logical pixels.
  factory FluentTypography.windows({Color? color}) {
    final family = FluentFonts.familiesFor(FluentFontPlatform.windows).text;
    TextStyle s(double size, double lineHeight, FontWeight weight) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: FluentFontFamily.baseFallback,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
    const r = FluentFontWeight.regular;
    const sb = FluentFontWeight.semibold;
    const b = FluentFontWeight.bold;

    final caption = s(12, 16, r);
    final captionStrong = s(12, 16, sb);
    final body = s(14, 20, r);
    final bodyStrong = s(14, 20, sb);
    final bodyLarge = s(18, 24, r);
    final bodyLargeStrong = s(18, 24, sb);
    final subtitle = s(20, 28, sb);
    final title = s(28, 36, sb);
    return FluentTypography(
      caption2: caption,
      caption2Strong: captionStrong,
      caption1: caption,
      caption1Strong: captionStrong,
      caption1Stronger: s(12, 16, b),
      body1: body,
      body1Strong: bodyStrong,
      body1Stronger: s(14, 20, b),
      body2: bodyLarge,
      body2Strong: bodyLargeStrong,
      subtitle2: bodyLargeStrong,
      subtitle2Stronger: s(18, 24, b),
      subtitle1: subtitle,
      title3: subtitle,
      title2: title,
      title1: title,
      largeTitle: s(40, 52, sb),
      display: s(68, 92, sb),
    );
  }

  /// The macOS ramp (native San Francisco Pro, pt).
  factory FluentTypography.macOS({Color? color}) {
    final families = FluentFonts.familiesFor(FluentFontPlatform.macOS);
    TextStyle s(
      double size,
      double lineHeight,
      FontWeight weight, {
      bool display = false,
    }) => TextStyle(
      fontFamily: display ? families.display : families.text,
      fontFamilyFallback: const ['-apple-system', 'Helvetica Neue'],
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
    const r = FluentFontWeight.regular;
    const sb = FluentFontWeight.semibold;
    const b = FluentFontWeight.bold;

    final caption = s(10, 13, r);
    final captionStrong = s(10, 13, sb);
    final body = s(13, 16, r);
    final bodyStrong = s(13, 16, sb);
    final title3 = s(15, 20, r);
    final title3Strong = s(15, 20, sb);
    return FluentTypography(
      caption2: caption,
      caption2Strong: captionStrong,
      caption1: caption,
      caption1Strong: captionStrong,
      caption1Stronger: s(10, 13, b),
      body1: body,
      body1Strong: bodyStrong,
      body1Stronger: s(13, 16, b),
      body2: title3,
      body2Strong: title3Strong,
      subtitle2: s(11, 14, r),
      subtitle2Stronger: s(11, 14, b),
      subtitle1: s(13, 16, b),
      title3: title3,
      title2: s(17, 22, r),
      title1: s(22, 26, r, display: true),
      largeTitle: s(26, 32, r, display: true),
      display: s(30, 40, b, display: true),
    );
  }

  /// The iOS ramp (San Francisco, pt). Line heights come from the docs — the
  /// Apple source carries no line-height token, it defers to Dynamic Type.
  factory FluentTypography.ios({Color? color}) {
    final families = FluentFonts.familiesFor(FluentFontPlatform.iOS);
    TextStyle s(
      double size,
      double lineHeight,
      FontWeight weight, {
      bool display = false,
    }) => TextStyle(
      fontFamily: display ? families.display : families.text,
      fontFamilyFallback: const ['-apple-system', 'Helvetica Neue'],
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
    const r = FluentFontWeight.regular;
    const sb = FluentFontWeight.semibold;
    const b = FluentFontWeight.bold;

    return FluentTypography(
      caption2: s(12, 16, r),
      caption2Strong: s(12, 16, sb),
      caption1: s(13, 18, r),
      caption1Strong: s(13, 18, sb),
      caption1Stronger: s(13, 18, b),
      body2: s(15, 20, r),
      body2Strong: s(15, 20, sb),
      body1: s(17, 22, r),
      body1Strong: s(17, 22, sb),
      body1Stronger: s(17, 22, b),
      subtitle2: s(17, 22, sb),
      subtitle2Stronger: s(17, 22, b),
      subtitle1: s(20, 25, sb, display: true),
      title3: s(20, 25, sb, display: true),
      title2: s(22, 28, sb, display: true),
      title1: s(28, 34, b, display: true),
      largeTitle: s(34, 41, b, display: true),
      display: s(60, 70, b, display: true),
    );
  }

  /// The Android ramp (Roboto, sp). Android is the only platform with tracking.
  factory FluentTypography.android({Color? color}) {
    final family = FluentFonts.familiesFor(FluentFontPlatform.android).text;
    TextStyle s(
      double size,
      double lineHeight,
      FontWeight weight, [
      double letterSpacing = 0,
    ]) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: const ['sans-serif'],
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
    const r = FluentFontWeight.regular;
    const m = FluentFontWeight.medium;
    const sb = FluentFontWeight.semibold;
    const b = FluentFontWeight.bold;

    return FluentTypography(
      // Android has no Caption2Strong upstream; aliased to caption2.
      caption2: s(12, 16, r),
      caption2Strong: s(12, 16, m),
      caption1: s(13, 18, r),
      caption1Strong: s(13, 18, m),
      caption1Stronger: s(13, 18, b),
      body2: s(14, 20, r),
      body2Strong: s(14, 20, m),
      body1: s(16, 24, r),
      body1Strong: s(16, 24, sb),
      body1Stronger: s(16, 24, b),
      subtitle2: s(18, 24, m),
      subtitle2Stronger: s(18, 24, b),
      subtitle1: s(20, 24, m),
      title3: s(18, 24, m),
      title2: s(20, 24, m),
      title1: s(24, 32, b),
      largeTitle: s(34, 44, r, -0.25),
      display: s(60, 72, r, -0.5),
    );
  }

  final TextStyle caption2;
  final TextStyle caption2Strong;
  final TextStyle caption1;
  final TextStyle caption1Strong;
  final TextStyle caption1Stronger;
  final TextStyle body1;
  final TextStyle body1Strong;
  final TextStyle body1Stronger;
  final TextStyle body2;
  final TextStyle body2Strong;
  final TextStyle subtitle2;
  final TextStyle subtitle2Stronger;
  final TextStyle subtitle1;
  final TextStyle title3;
  final TextStyle title2;
  final TextStyle title1;
  final TextStyle largeTitle;
  final TextStyle display;

  /// Repaints every style in [color]. Used by the theme to bind the ramp to
  /// `neutralForeground1`.
  FluentTypography withColor(Color color) => FluentTypography(
    caption2: caption2.copyWith(color: color),
    caption2Strong: caption2Strong.copyWith(color: color),
    caption1: caption1.copyWith(color: color),
    caption1Strong: caption1Strong.copyWith(color: color),
    caption1Stronger: caption1Stronger.copyWith(color: color),
    body1: body1.copyWith(color: color),
    body1Strong: body1Strong.copyWith(color: color),
    body1Stronger: body1Stronger.copyWith(color: color),
    body2: body2.copyWith(color: color),
    body2Strong: body2Strong.copyWith(color: color),
    subtitle2: subtitle2.copyWith(color: color),
    subtitle2Stronger: subtitle2Stronger.copyWith(color: color),
    subtitle1: subtitle1.copyWith(color: color),
    title3: title3.copyWith(color: color),
    title2: title2.copyWith(color: color),
    title1: title1.copyWith(color: color),
    largeTitle: largeTitle.copyWith(color: color),
    display: display.copyWith(color: color),
  );

  /// Value equality over all 18 styles.
  ///
  /// Without this the class is `@immutable` but compares by identity, so two
  /// separately built ramps are never equal — which makes `FluentThemeData ==`
  /// always false and `FluentTheme.updateShouldNotify` always true, rebuilding
  /// every theme dependent on every ancestor rebuild.
  @override
  bool operator ==(Object other) =>
      other is FluentTypography &&
      other.caption2 == caption2 &&
      other.caption2Strong == caption2Strong &&
      other.caption1 == caption1 &&
      other.caption1Strong == caption1Strong &&
      other.caption1Stronger == caption1Stronger &&
      other.body1 == body1 &&
      other.body1Strong == body1Strong &&
      other.body1Stronger == body1Stronger &&
      other.body2 == body2 &&
      other.body2Strong == body2Strong &&
      other.subtitle2 == subtitle2 &&
      other.subtitle2Stronger == subtitle2Stronger &&
      other.subtitle1 == subtitle1 &&
      other.title3 == title3 &&
      other.title2 == title2 &&
      other.title1 == title1 &&
      other.largeTitle == largeTitle &&
      other.display == display;

  @override
  int get hashCode => Object.hashAll([
    caption2,
    caption2Strong,
    caption1,
    caption1Strong,
    caption1Stronger,
    body1,
    body1Strong,
    body1Stronger,
    body2,
    body2Strong,
    subtitle2,
    subtitle2Stronger,
    subtitle1,
    title3,
    title2,
    title1,
    largeTitle,
    display,
  ]);
}
