// ignore_for_file: public_member_api_docs
// Each member below is a single stop on a named numeric scale — the
// identifier and its value are the documentation (`size20 = 2`,
// `ultraFast = 50ms`). The class doc explains the scale; per-stop prose
// would restate the name and nothing more. Real API elsewhere is covered.
import 'package:flutter/widgets.dart';

import 'brand_generator.dart';

/// A Fluent brand ramp: 16 stops, `10` (darkest) through `160` (lightest).
///
/// Indexed with the Fluent stop numbers so the alias tables read exactly like
/// the upstream source: `brand[80]`, `brand[160]`.
///
/// Source: `microsoft/fluentui` `packages/tokens/src/global/brandColors.ts`.
@immutable
class FluentBrandRamp {
  const FluentBrandRamp(this._shades);

  /// Generates a ramp from a single key color, via the Theme Designer
  /// algorithm — see [FluentBrandGenerator] for the parameters.
  ///
  /// This is how you brand the system without hand-picking 16 hexes. It will
  /// not reproduce the named constants below: those are hand-authored upstream,
  /// and the generator does not even place your key color at stop 80. Use this
  /// for your own brand, the constants for fidelity to Microsoft's themes.
  factory FluentBrandRamp.fromKeyColor(
    Color keyColor, {
    double? vibrancy,
    double hueTorsion = 0,
  }) => FluentBrandRamp(
    FluentBrandGenerator.shades(
      keyColor,
      vibrancy: vibrancy,
      hueTorsion: hueTorsion,
    ),
  );

  final List<Color> _shades;

  /// [stop] must be one of 10, 20, … 160.
  Color operator [](int stop) {
    assert(
      stop >= 10 && stop <= 160 && stop % 10 == 0,
      'Bad brand stop: $stop',
    );
    return _shades[stop ~/ 10 - 1];
  }

  /// The Fluent 2 web default. This is what `webLightTheme` / `webDarkTheme`
  /// ship with — it is *not* the classic Communication Blue ramp.
  static const FluentBrandRamp web = FluentBrandRamp([
    Color(0xFF061724),
    Color(0xFF082338),
    Color(0xFF0A2E4A),
    Color(0xFF0C3B5E),
    Color(0xFF0E4775),
    Color(0xFF0F548C),
    Color(0xFF115EA3),
    Color(0xFF0F6CBD),
    Color(0xFF2886DE),
    Color(0xFF479EF5),
    Color(0xFF62ABF5),
    Color(0xFF77B7F7),
    Color(0xFF96C6FA),
    Color(0xFFB4D6FA),
    Color(0xFFCFE4FA),
    Color(0xFFEBF3FC),
  ]);

  /// Microsoft Teams.
  static const FluentBrandRamp teams = FluentBrandRamp([
    Color(0xFF2B2B40),
    Color(0xFF2F2F4A),
    Color(0xFF333357),
    Color(0xFF383966),
    Color(0xFF3D3E78),
    Color(0xFF444791),
    Color(0xFF4F52B2),
    Color(0xFF5B5FC7),
    Color(0xFF7579EB),
    Color(0xFF7F85F5),
    Color(0xFF9299F7),
    Color(0xFFAAB1FA),
    Color(0xFFB6BCFA),
    Color(0xFFC5CBFA),
    Color(0xFFDCE0FA),
    Color(0xFFE8EBFA),
  ]);

  /// Teams V21.
  static const FluentBrandRamp teamsV21 = FluentBrandRamp([
    Color(0xFF29274F),
    Color(0xFF2F2A5E),
    Color(0xFF352E70),
    Color(0xFF3B3185),
    Color(0xFF44359E),
    Color(0xFF4D3ABA),
    Color(0xFF5A40DB),
    Color(0xFF654CF5),
    Color(0xFF7769FA),
    Color(0xFF887DFF),
    Color(0xFF9791FF),
    Color(0xFFABA8FF),
    Color(0xFFBAB8FF),
    Color(0xFFC8C7FF),
    Color(0xFFDCDBFF),
    Color(0xFFE8E8FF),
  ]);

  /// Office. Defined upstream but no shipped theme uses it — you have to build
  /// one with `FluentThemeData.light(brand: FluentBrandRamp.office)`.
  static const FluentBrandRamp office = FluentBrandRamp([
    Color(0xFF29130B),
    Color(0xFF4D2415),
    Color(0xFF792000),
    Color(0xFF99482B),
    Color(0xFFA52C00),
    Color(0xFFC33400),
    Color(0xFFE06A3F),
    Color(0xFFD83B01),
    Color(0xFFDD4F1B),
    Color(0xFFFE7948),
    Color(0xFFFF865A),
    Color(0xFFFF9973),
    Color(0xFFE8825D),
    Color(0xFFFFB498),
    Color(0xFFF4BEAA),
    Color(0xFFF9DCD1),
  ]);

  /// Classic Communication Blue. Reconstructed from the token pipeline's
  /// generated comments — upstream never exports it as a named constant.
  static const FluentBrandRamp communicationBlue = FluentBrandRamp([
    Color(0xFF001526),
    Color(0xFF002848),
    Color(0xFF043862),
    Color(0xFF004578),
    Color(0xFF004C87),
    Color(0xFF005A9E),
    Color(0xFF106EBE),
    Color(0xFF0078D4),
    Color(0xFF1890F1),
    Color(0xFF2899F5),
    Color(0xFF3AA0F3),
    Color(0xFF6CB8F6),
    Color(0xFF82C7FF),
    Color(0xFFC7E0F4),
    Color(0xFFDEECF9),
    Color(0xFFEFF6FC),
  ]);
}

/// The global neutral ramp. Stops are the Fluent numbers (2…98, plus 99), where
/// the number is the approximate lightness percentage.
///
/// Source: `packages/tokens/src/global/colors.ts`.
abstract final class FluentGrey {
  static const Map<int, Color> ramp = {
    2: Color(0xFF050505),
    4: Color(0xFF0A0A0A),
    6: Color(0xFF0F0F0F),
    8: Color(0xFF141414),
    10: Color(0xFF1A1A1A),
    12: Color(0xFF1F1F1F),
    14: Color(0xFF242424),
    16: Color(0xFF292929),
    18: Color(0xFF2E2E2E),
    20: Color(0xFF333333),
    22: Color(0xFF383838),
    24: Color(0xFF3D3D3D),
    26: Color(0xFF424242),
    28: Color(0xFF474747),
    30: Color(0xFF4D4D4D),
    32: Color(0xFF525252),
    34: Color(0xFF575757),
    36: Color(0xFF5C5C5C),
    38: Color(0xFF616161),
    40: Color(0xFF666666),
    42: Color(0xFF6B6B6B),
    44: Color(0xFF707070),
    46: Color(0xFF757575),
    48: Color(0xFF7A7A7A),
    50: Color(0xFF808080),
    52: Color(0xFF858585),
    54: Color(0xFF8A8A8A),
    56: Color(0xFF8F8F8F),
    58: Color(0xFF949494),
    60: Color(0xFF999999),
    62: Color(0xFF9E9E9E),
    64: Color(0xFFA3A3A3),
    66: Color(0xFFA8A8A8),
    68: Color(0xFFADADAD),
    70: Color(0xFFB3B3B3),
    72: Color(0xFFB8B8B8),
    74: Color(0xFFBDBDBD),
    76: Color(0xFFC2C2C2),
    78: Color(0xFFC7C7C7),
    80: Color(0xFFCCCCCC),
    82: Color(0xFFD1D1D1),
    84: Color(0xFFD6D6D6),
    86: Color(0xFFDBDBDB),
    88: Color(0xFFE0E0E0),
    90: Color(0xFFE6E6E6),
    92: Color(0xFFEBEBEB),
    94: Color(0xFFF0F0F0),
    96: Color(0xFFF5F5F5),
    98: Color(0xFFFAFAFA),
    99: Color(0xFFFCFCFC),
  };

  /// [stop] must be an even number 2–98, or 99.
  static Color at(int stop) =>
      ramp[stop] ?? (throw ArgumentError.value(stop, 'stop', 'No such grey'));

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

/// Windows high-contrast system colors.
abstract final class FluentHighContrast {
  static const Color hyperlink = Color(0xFFFFFF00);
  static const Color highlight = Color(0xFF1AEBFF);
  static const Color disabled = Color(0xFF3FF23F);
  static const Color canvas = Color(0xFF000000);
  static const Color canvasText = Color(0xFFFFFFFF);
  static const Color highlightText = Color(0xFF000000);
  static const Color buttonText = Color(0xFF000000);
  static const Color buttonFace = Color(0xFFFFFFFF);
}
