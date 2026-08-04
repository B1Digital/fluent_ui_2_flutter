// ignore_for_file: public_member_api_docs
// Each member below is a single stop on a named numeric scale — the
// identifier and its value are the documentation (`size20 = 2`,
// `ultraFast = 50ms`). The class doc explains the scale; per-stop prose
// would restate the name and nothing more. Real API elsewhere is covered.
import 'package:flutter/painting.dart';

/// Fluent elevation levels. The number is the key shadow's blur radius.
enum FluentElevation {
  shadow2(ambientBlur: 2, keyOffset: 1, keyBlur: 2),
  shadow4(ambientBlur: 2, keyOffset: 2, keyBlur: 4),
  shadow8(ambientBlur: 2, keyOffset: 4, keyBlur: 8),
  shadow16(ambientBlur: 2, keyOffset: 8, keyBlur: 16),
  shadow28(ambientBlur: 8, keyOffset: 14, keyBlur: 28),
  shadow64(ambientBlur: 8, keyOffset: 32, keyBlur: 64);

  const FluentElevation({
    required this.ambientBlur,
    required this.keyOffset,
    required this.keyBlur,
  });

  /// Blur of the ambient layer, which sits at zero offset.
  final double ambientBlur;

  /// Downward offset of the key layer.
  final double keyOffset;
  final double keyBlur;

  /// Builds the two-layer shadow. Pass the ambient/key colors from the theme —
  /// `FluentColors.neutralShadowAmbient` / `neutralShadowKey` for surfaces, or
  /// the `brandShadow*` pair for shadows cast onto brand color.
  List<BoxShadow> shadows({required Color ambient, required Color key}) => [
    BoxShadow(color: ambient, blurRadius: ambientBlur),
    BoxShadow(color: key, offset: Offset(0, keyOffset), blurRadius: keyBlur),
  ];
}

/// Fluent's shadow-opacity model.
///
/// A fixed shadow reads as a different elevation depending on what it falls on,
/// so Fluent derives opacity from the surface's luminosity. This is why brand
/// shadows are 30%/25% while neutral shadows are 12%/14%.
abstract final class FluentShadowLuminosity {
  /// Weighted luminosity of [color], 0–255. Note this is the *non-linearized*
  /// form the Fluent docs specify — it is not WCAG relative luminance.
  static double luminosity(Color color) =>
      0.2126 * (color.r * 255) +
      0.7152 * (color.g * 255) +
      0.0722 * (color.b * 255);

  /// Ambient ("shadow 1") opacity for a shadow cast on [surface], 0–1.
  static double ambientOpacity(Color surface) =>
      ((42 - 0.116 * luminosity(surface)).roundToDouble() / 100).clamp(
        0.0,
        1.0,
      );

  /// Key ("shadow 2") opacity for a shadow cast on [surface], 0–1.
  static double keyOpacity(Color surface) =>
      ((34 - 0.09 * luminosity(surface)).roundToDouble() / 100).clamp(0.0, 1.0);

  /// The full shadow pair for an arbitrary [surface] color, opacities derived
  /// rather than taken from the neutral/brand token pairs.
  static List<BoxShadow> shadowsOn(Color surface, FluentElevation level) =>
      level.shadows(
        ambient: Color.fromRGBO(0, 0, 0, ambientOpacity(surface)),
        key: Color.fromRGBO(0, 0, 0, keyOpacity(surface)),
      );
}

/// Windows acrylic effect-graph parameters, from WinUI's `AcrylicBrush`.
///
/// This is the *desktop* recipe: blur radius, saturation, noise and the tint /
/// luminosity opacities that WinUI composes to produce acrylic. It is not the
/// same thing as `FluentAcrylic`, which carries the Fluent 2 acrylic **colour
/// tokens** published in the design file — note the two even disagree on blur
/// (30 here, 60 there), because they describe different pipelines.
///
/// Mica is composed by the Windows compositor and has no published constants;
/// there is deliberately no Mica entry here.
abstract final class FluentWindowsAcrylic {
  static const double blurRadius = 30;
  static const double noiseOpacity = 0.02;
  static const double saturation = 1.25;

  /// Blended with `BlendMode.exclusion` after saturation.
  static const Color exclusion = Color(0x1AFFFFFF);

  static const Duration tintTransition = Duration(milliseconds: 500);

  /// Default in-app acrylic tint.
  static const Color tintLight = Color(0xFFFCFCFC);
  static const Color tintDark = Color(0xFF2C2C2C);
  static const double tintOpacityLight = 0.0;
  static const double tintOpacityDark = 0.15;
  static const double luminosityOpacityLight = 0.85;
  static const double luminosityOpacityDark = 0.96;

  /// Used when the backdrop cannot be sampled (offscreen, low power, etc.).
  static const Color fallbackLight = Color(0xFFF9F9F9);
  static const Color fallbackDark = Color(0xFF2C2C2C);

  /// Base (non-in-app) acrylic.
  static const Color baseTintLight = Color(0xFFF3F3F3);
  static const Color baseTintDark = Color(0xFF202020);
  static const double baseLuminosityOpacityLight = 0.90;
  static const double baseLuminosityOpacityDark = 0.96;
}
