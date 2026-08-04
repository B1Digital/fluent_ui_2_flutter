import 'package:flutter/widgets.dart';

import 'color_token.dart';
import 'global_colors.dart';
import 'materials.dart';
import 'palette_colors.dart';

Color _g(int stop) => FluentGrey.ramp[stop]!;
const Color _white = FluentGrey.white;
const Color _black = FluentGrey.black;
const Color _clear = FluentGrey.transparent;

/// The Fluent 2 alias (semantic) color layer.
///
/// Each token is a getter that resolves against [brightness] and [brand], so
/// light and dark sit on one line and stay verifiable against the upstream
/// `alias/lightColor.ts` / `alias/darkColor.ts`.
///
/// To rebrand, pass a different [brand] ramp. To override individual tokens,
/// subclass and override the getter — they are all virtual.
@immutable
class FluentColors {
  /// Creates a palette for the given brightness and brand ramp.
  const FluentColors({
    this.brightness = Brightness.light,
    this.brand = FluentBrandRamp.web,
    this.overrides,
  });

  /// Which of the light and dark tables each token resolves against.
  final Brightness brightness;

  /// The 16-stop brand ramp every `brand*` token reads from.
  final FluentBrandRamp brand;

  /// Per-token overrides applied before the computed value.
  ///
  /// The counterpart of a `PartialTheme` handed to a nested `FluentProvider`
  /// upstream. Usually set through `FluentThemeOverride` rather than directly.
  final Map<FluentColorToken, Color>? overrides;

  /// Override lookup. Every alias getter routes through this.
  ///
  /// Protected rather than private because the theme variants live in their own
  /// library, and Dart privacy is library-scoped. Consumers want [resolve].
  @protected
  @pragma('vm:prefer-inline')
  Color applyOverride(FluentColorToken token, Color computed) =>
      overrides?[token] ?? computed;

  /// Resolves any token by identity — the analogue of `tokens[key]` upstream.
  Color resolve(FluentColorToken token) => switch (token) {
    FluentColorToken.neutralForeground1 => neutralForeground1,
    FluentColorToken.neutralForeground1Hover => neutralForeground1Hover,
    FluentColorToken.neutralForeground1Pressed => neutralForeground1Pressed,
    FluentColorToken.neutralForeground1Selected => neutralForeground1Selected,
    FluentColorToken.neutralForeground2 => neutralForeground2,
    FluentColorToken.neutralForeground2Hover => neutralForeground2Hover,
    FluentColorToken.neutralForeground2Pressed => neutralForeground2Pressed,
    FluentColorToken.neutralForeground2Selected => neutralForeground2Selected,
    FluentColorToken.neutralForeground2BrandHover =>
      neutralForeground2BrandHover,
    FluentColorToken.neutralForeground2BrandPressed =>
      neutralForeground2BrandPressed,
    FluentColorToken.neutralForeground2BrandSelected =>
      neutralForeground2BrandSelected,
    FluentColorToken.neutralForeground3 => neutralForeground3,
    FluentColorToken.neutralForeground3Hover => neutralForeground3Hover,
    FluentColorToken.neutralForeground3Pressed => neutralForeground3Pressed,
    FluentColorToken.neutralForeground3Selected => neutralForeground3Selected,
    FluentColorToken.neutralForeground3BrandHover =>
      neutralForeground3BrandHover,
    FluentColorToken.neutralForeground3BrandPressed =>
      neutralForeground3BrandPressed,
    FluentColorToken.neutralForeground3BrandSelected =>
      neutralForeground3BrandSelected,
    FluentColorToken.neutralForeground4 => neutralForeground4,
    FluentColorToken.neutralForeground5 => neutralForeground5,
    FluentColorToken.neutralForeground5Hover => neutralForeground5Hover,
    FluentColorToken.neutralForeground5Pressed => neutralForeground5Pressed,
    FluentColorToken.neutralForeground5Selected => neutralForeground5Selected,
    FluentColorToken.neutralForegroundDisabled => neutralForegroundDisabled,
    FluentColorToken.neutralForegroundInvertedDisabled =>
      neutralForegroundInvertedDisabled,
    FluentColorToken.neutralForeground1Static => neutralForeground1Static,
    FluentColorToken.neutralForegroundStaticInverted =>
      neutralForegroundStaticInverted,
    FluentColorToken.neutralForegroundInverted => neutralForegroundInverted,
    FluentColorToken.neutralForegroundInvertedHover =>
      neutralForegroundInvertedHover,
    FluentColorToken.neutralForegroundInvertedPressed =>
      neutralForegroundInvertedPressed,
    FluentColorToken.neutralForegroundInvertedSelected =>
      neutralForegroundInvertedSelected,
    FluentColorToken.neutralForegroundInverted2 => neutralForegroundInverted2,
    FluentColorToken.neutralForegroundOnBrand => neutralForegroundOnBrand,
    FluentColorToken.neutralForegroundInvertedLink =>
      neutralForegroundInvertedLink,
    FluentColorToken.neutralForegroundInvertedLinkHover =>
      neutralForegroundInvertedLinkHover,
    FluentColorToken.neutralForegroundInvertedLinkPressed =>
      neutralForegroundInvertedLinkPressed,
    FluentColorToken.neutralForegroundInvertedLinkSelected =>
      neutralForegroundInvertedLinkSelected,
    FluentColorToken.brandForegroundLink => brandForegroundLink,
    FluentColorToken.brandForegroundLinkHover => brandForegroundLinkHover,
    FluentColorToken.brandForegroundLinkPressed => brandForegroundLinkPressed,
    FluentColorToken.brandForegroundLinkSelected => brandForegroundLinkSelected,
    FluentColorToken.neutralForeground2Link => neutralForeground2Link,
    FluentColorToken.neutralForeground2LinkHover => neutralForeground2LinkHover,
    FluentColorToken.neutralForeground2LinkPressed =>
      neutralForeground2LinkPressed,
    FluentColorToken.neutralForeground2LinkSelected =>
      neutralForeground2LinkSelected,
    FluentColorToken.compoundBrandForeground1 => compoundBrandForeground1,
    FluentColorToken.compoundBrandForeground1Hover =>
      compoundBrandForeground1Hover,
    FluentColorToken.compoundBrandForeground1Pressed =>
      compoundBrandForeground1Pressed,
    FluentColorToken.brandForeground1 => brandForeground1,
    FluentColorToken.brandForeground2 => brandForeground2,
    FluentColorToken.brandForeground2Hover => brandForeground2Hover,
    FluentColorToken.brandForeground2Pressed => brandForeground2Pressed,
    FluentColorToken.brandForegroundInverted => brandForegroundInverted,
    FluentColorToken.brandForegroundInvertedHover =>
      brandForegroundInvertedHover,
    FluentColorToken.brandForegroundInvertedPressed =>
      brandForegroundInvertedPressed,
    FluentColorToken.brandForegroundOnLight => brandForegroundOnLight,
    FluentColorToken.brandForegroundOnLightHover => brandForegroundOnLightHover,
    FluentColorToken.brandForegroundOnLightPressed =>
      brandForegroundOnLightPressed,
    FluentColorToken.brandForegroundOnLightSelected =>
      brandForegroundOnLightSelected,
    FluentColorToken.neutralBackground1 => neutralBackground1,
    FluentColorToken.neutralBackground1Hover => neutralBackground1Hover,
    FluentColorToken.neutralBackground1Pressed => neutralBackground1Pressed,
    FluentColorToken.neutralBackground1Selected => neutralBackground1Selected,
    FluentColorToken.neutralBackground2 => neutralBackground2,
    FluentColorToken.neutralBackground2Hover => neutralBackground2Hover,
    FluentColorToken.neutralBackground2Pressed => neutralBackground2Pressed,
    FluentColorToken.neutralBackground2Selected => neutralBackground2Selected,
    FluentColorToken.neutralBackground3 => neutralBackground3,
    FluentColorToken.neutralBackground3Hover => neutralBackground3Hover,
    FluentColorToken.neutralBackground3Pressed => neutralBackground3Pressed,
    FluentColorToken.neutralBackground3Selected => neutralBackground3Selected,
    FluentColorToken.neutralBackground4 => neutralBackground4,
    FluentColorToken.neutralBackground4Hover => neutralBackground4Hover,
    FluentColorToken.neutralBackground4Pressed => neutralBackground4Pressed,
    FluentColorToken.neutralBackground4Selected => neutralBackground4Selected,
    FluentColorToken.neutralBackground5 => neutralBackground5,
    FluentColorToken.neutralBackground5Hover => neutralBackground5Hover,
    FluentColorToken.neutralBackground5Pressed => neutralBackground5Pressed,
    FluentColorToken.neutralBackground5Selected => neutralBackground5Selected,
    FluentColorToken.neutralBackground6 => neutralBackground6,
    FluentColorToken.neutralBackground7 => neutralBackground7,
    FluentColorToken.neutralBackground7Hover => neutralBackground7Hover,
    FluentColorToken.neutralBackground7Pressed => neutralBackground7Pressed,
    FluentColorToken.neutralBackground7Selected => neutralBackground7Selected,
    FluentColorToken.neutralBackground8 => neutralBackground8,
    FluentColorToken.neutralBackgroundInverted => neutralBackgroundInverted,
    FluentColorToken.neutralBackgroundInvertedHover =>
      neutralBackgroundInvertedHover,
    FluentColorToken.neutralBackgroundInvertedPressed =>
      neutralBackgroundInvertedPressed,
    FluentColorToken.neutralBackgroundInvertedSelected =>
      neutralBackgroundInvertedSelected,
    FluentColorToken.neutralBackgroundStatic => neutralBackgroundStatic,
    FluentColorToken.neutralBackgroundAlpha => neutralBackgroundAlpha,
    FluentColorToken.neutralBackgroundAlpha2 => neutralBackgroundAlpha2,
    FluentColorToken.neutralBackgroundDisabled => neutralBackgroundDisabled,
    FluentColorToken.neutralBackgroundDisabled2 => neutralBackgroundDisabled2,
    FluentColorToken.neutralBackgroundInvertedDisabled =>
      neutralBackgroundInvertedDisabled,
    FluentColorToken.subtleBackground => subtleBackground,
    FluentColorToken.subtleBackgroundHover => subtleBackgroundHover,
    FluentColorToken.subtleBackgroundPressed => subtleBackgroundPressed,
    FluentColorToken.subtleBackgroundSelected => subtleBackgroundSelected,
    FluentColorToken.subtleBackgroundLightAlphaHover =>
      subtleBackgroundLightAlphaHover,
    FluentColorToken.subtleBackgroundLightAlphaPressed =>
      subtleBackgroundLightAlphaPressed,
    FluentColorToken.subtleBackgroundLightAlphaSelected =>
      subtleBackgroundLightAlphaSelected,
    FluentColorToken.subtleBackgroundInverted => subtleBackgroundInverted,
    FluentColorToken.subtleBackgroundInvertedHover =>
      subtleBackgroundInvertedHover,
    FluentColorToken.subtleBackgroundInvertedPressed =>
      subtleBackgroundInvertedPressed,
    FluentColorToken.subtleBackgroundInvertedSelected =>
      subtleBackgroundInvertedSelected,
    FluentColorToken.transparentBackground => transparentBackground,
    FluentColorToken.transparentBackgroundHover => transparentBackgroundHover,
    FluentColorToken.transparentBackgroundPressed =>
      transparentBackgroundPressed,
    FluentColorToken.transparentBackgroundSelected =>
      transparentBackgroundSelected,
    FluentColorToken.neutralStencil1 => neutralStencil1,
    FluentColorToken.neutralStencil2 => neutralStencil2,
    FluentColorToken.neutralStencil1Alpha => neutralStencil1Alpha,
    FluentColorToken.neutralStencil2Alpha => neutralStencil2Alpha,
    FluentColorToken.backgroundOverlay => backgroundOverlay,
    FluentColorToken.scrollbarOverlay => scrollbarOverlay,
    FluentColorToken.brandBackground => brandBackground,
    FluentColorToken.brandBackgroundHover => brandBackgroundHover,
    FluentColorToken.brandBackgroundPressed => brandBackgroundPressed,
    FluentColorToken.brandBackgroundSelected => brandBackgroundSelected,
    FluentColorToken.compoundBrandBackground => compoundBrandBackground,
    FluentColorToken.compoundBrandBackgroundHover =>
      compoundBrandBackgroundHover,
    FluentColorToken.compoundBrandBackgroundPressed =>
      compoundBrandBackgroundPressed,
    FluentColorToken.brandBackgroundStatic => brandBackgroundStatic,
    FluentColorToken.brandBackground2 => brandBackground2,
    FluentColorToken.brandBackground2Hover => brandBackground2Hover,
    FluentColorToken.brandBackground2Pressed => brandBackground2Pressed,
    FluentColorToken.brandBackground3Static => brandBackground3Static,
    FluentColorToken.brandBackground4Static => brandBackground4Static,
    FluentColorToken.brandBackgroundInverted => brandBackgroundInverted,
    FluentColorToken.brandBackgroundInvertedHover =>
      brandBackgroundInvertedHover,
    FluentColorToken.brandBackgroundInvertedPressed =>
      brandBackgroundInvertedPressed,
    FluentColorToken.brandBackgroundInvertedSelected =>
      brandBackgroundInvertedSelected,
    FluentColorToken.neutralCardBackground => neutralCardBackground,
    FluentColorToken.neutralCardBackgroundHover => neutralCardBackgroundHover,
    FluentColorToken.neutralCardBackgroundPressed =>
      neutralCardBackgroundPressed,
    FluentColorToken.neutralCardBackgroundSelected =>
      neutralCardBackgroundSelected,
    FluentColorToken.neutralCardBackgroundDisabled =>
      neutralCardBackgroundDisabled,
    FluentColorToken.neutralStrokeAccessible => neutralStrokeAccessible,
    FluentColorToken.neutralStrokeAccessibleHover =>
      neutralStrokeAccessibleHover,
    FluentColorToken.neutralStrokeAccessiblePressed =>
      neutralStrokeAccessiblePressed,
    FluentColorToken.neutralStrokeAccessibleSelected =>
      neutralStrokeAccessibleSelected,
    FluentColorToken.neutralStroke1 => neutralStroke1,
    FluentColorToken.neutralStroke1Hover => neutralStroke1Hover,
    FluentColorToken.neutralStroke1Pressed => neutralStroke1Pressed,
    FluentColorToken.neutralStroke1Selected => neutralStroke1Selected,
    FluentColorToken.neutralStroke2 => neutralStroke2,
    FluentColorToken.neutralStroke3 => neutralStroke3,
    FluentColorToken.neutralStroke4 => neutralStroke4,
    FluentColorToken.neutralStroke4Hover => neutralStroke4Hover,
    FluentColorToken.neutralStroke4Pressed => neutralStroke4Pressed,
    FluentColorToken.neutralStroke4Selected => neutralStroke4Selected,
    FluentColorToken.neutralStrokeSubtle => neutralStrokeSubtle,
    FluentColorToken.neutralStrokeOnBrand => neutralStrokeOnBrand,
    FluentColorToken.neutralStrokeOnBrand2 => neutralStrokeOnBrand2,
    FluentColorToken.neutralStrokeOnBrand2Hover => neutralStrokeOnBrand2Hover,
    FluentColorToken.neutralStrokeOnBrand2Pressed =>
      neutralStrokeOnBrand2Pressed,
    FluentColorToken.neutralStrokeOnBrand2Selected =>
      neutralStrokeOnBrand2Selected,
    FluentColorToken.brandStroke1 => brandStroke1,
    FluentColorToken.brandStroke2 => brandStroke2,
    FluentColorToken.brandStroke2Hover => brandStroke2Hover,
    FluentColorToken.brandStroke2Pressed => brandStroke2Pressed,
    FluentColorToken.brandStroke2Contrast => brandStroke2Contrast,
    FluentColorToken.compoundBrandStroke => compoundBrandStroke,
    FluentColorToken.compoundBrandStrokeHover => compoundBrandStrokeHover,
    FluentColorToken.compoundBrandStrokePressed => compoundBrandStrokePressed,
    FluentColorToken.neutralStrokeDisabled => neutralStrokeDisabled,
    FluentColorToken.neutralStrokeDisabled2 => neutralStrokeDisabled2,
    FluentColorToken.neutralStrokeInvertedDisabled =>
      neutralStrokeInvertedDisabled,
    FluentColorToken.transparentStroke => transparentStroke,
    FluentColorToken.transparentStrokeInteractive =>
      transparentStrokeInteractive,
    FluentColorToken.transparentStrokeDisabled => transparentStrokeDisabled,
    FluentColorToken.neutralStrokeAlpha => neutralStrokeAlpha,
    FluentColorToken.neutralStrokeAlpha2 => neutralStrokeAlpha2,
    FluentColorToken.strokeFocus1 => strokeFocus1,
    FluentColorToken.strokeFocus2 => strokeFocus2,
    FluentColorToken.neutralShadowAmbient => neutralShadowAmbient,
    FluentColorToken.neutralShadowKey => neutralShadowKey,
    FluentColorToken.neutralShadowAmbientLighter => neutralShadowAmbientLighter,
    FluentColorToken.neutralShadowKeyLighter => neutralShadowKeyLighter,
    FluentColorToken.neutralShadowAmbientDarker => neutralShadowAmbientDarker,
    FluentColorToken.neutralShadowKeyDarker => neutralShadowKeyDarker,
    FluentColorToken.brandShadowAmbient => brandShadowAmbient,
    FluentColorToken.brandShadowKey => brandShadowKey,
    FluentColorToken.statusDangerBackground1 => statusDangerBackground1,
    FluentColorToken.statusDangerBackground2 => statusDangerBackground2,
    FluentColorToken.statusDangerBackground3 => statusDangerBackground3,
    FluentColorToken.statusDangerBackground3Hover =>
      statusDangerBackground3Hover,
    FluentColorToken.statusDangerBackground3Pressed =>
      statusDangerBackground3Pressed,
    FluentColorToken.statusDangerForeground1 => statusDangerForeground1,
    FluentColorToken.statusDangerForeground2 => statusDangerForeground2,
    FluentColorToken.statusDangerForeground3 => statusDangerForeground3,
    FluentColorToken.statusDangerForegroundInverted =>
      statusDangerForegroundInverted,
    FluentColorToken.statusDangerBorderActive => statusDangerBorderActive,
    FluentColorToken.statusDangerBorder1 => statusDangerBorder1,
    FluentColorToken.statusDangerBorder2 => statusDangerBorder2,
    FluentColorToken.statusSuccessBackground1 => statusSuccessBackground1,
    FluentColorToken.statusSuccessBackground2 => statusSuccessBackground2,
    FluentColorToken.statusSuccessBackground3 => statusSuccessBackground3,
    FluentColorToken.statusSuccessForeground1 => statusSuccessForeground1,
    FluentColorToken.statusSuccessForeground2 => statusSuccessForeground2,
    FluentColorToken.statusSuccessForeground3 => statusSuccessForeground3,
    FluentColorToken.statusSuccessForegroundInverted =>
      statusSuccessForegroundInverted,
    FluentColorToken.statusSuccessBorderActive => statusSuccessBorderActive,
    FluentColorToken.statusSuccessBorder1 => statusSuccessBorder1,
    FluentColorToken.statusSuccessBorder2 => statusSuccessBorder2,
    FluentColorToken.statusWarningBackground1 => statusWarningBackground1,
    FluentColorToken.statusWarningBackground2 => statusWarningBackground2,
    FluentColorToken.statusWarningBackground3 => statusWarningBackground3,
    FluentColorToken.statusWarningForeground1 => statusWarningForeground1,
    FluentColorToken.statusWarningForeground2 => statusWarningForeground2,
    FluentColorToken.statusWarningForeground3 => statusWarningForeground3,
    FluentColorToken.statusWarningForegroundInverted =>
      statusWarningForegroundInverted,
    FluentColorToken.statusWarningBorderActive => statusWarningBorderActive,
    FluentColorToken.statusWarningBorder1 => statusWarningBorder1,
    FluentColorToken.statusWarningBorder2 => statusWarningBorder2,
    FluentColorToken.statusSevereBackground1 => statusSevereBackground1,
    FluentColorToken.statusSevereBackground2 => statusSevereBackground2,
    FluentColorToken.statusSevereBackground3 => statusSevereBackground3,
    FluentColorToken.statusSevereForeground1 => statusSevereForeground1,
    FluentColorToken.statusSevereForeground2 => statusSevereForeground2,
    FluentColorToken.statusSevereForeground3 => statusSevereForeground3,
    FluentColorToken.statusSevereForegroundInverted =>
      statusSevereForegroundInverted,
    FluentColorToken.statusSevereBorder1 => statusSevereBorder1,
    FluentColorToken.statusSevereBorder2 => statusSevereBorder2,
    FluentColorToken.statusAvailableForeground3 => statusAvailableForeground3,
    FluentColorToken.statusAwayBackground3 => statusAwayBackground3,
    FluentColorToken.statusOofForeground3 => statusOofForeground3,
  };

  /// This palette with [extra] merged over any existing [overrides].
  ///
  /// Overridden by each variant so the concrete theme survives: overriding a
  /// token on high contrast must not silently demote it to the default palette.
  FluentColors withOverrides(Map<FluentColorToken, Color> extra) =>
      FluentColors(
        brightness: brightness,
        brand: brand,
        overrides: {...?overrides, ...extra},
      );

  bool get _d => brightness == Brightness.dark;

  /// The persona / accent palette layer, upstream's `colorPalette*`.
  FluentPaletteColors get palette =>
      FluentPaletteColors(brightness: brightness);

  /// The Acrylic material tokens.
  FluentAcrylic get acrylic => FluentAcrylic(brightness: brightness);

  // ---------------------------------------------------------------- foreground
  /// Upstream `colorNeutralForeground1`.
  Color get neutralForeground1 =>
      applyOverride(FluentColorToken.neutralForeground1, _d ? _white : _g(14));

  /// Upstream `colorNeutralForeground1Hover`.
  Color get neutralForeground1Hover => applyOverride(
    FluentColorToken.neutralForeground1Hover,
    neutralForeground1,
  );

  /// Upstream `colorNeutralForeground1Pressed`.
  Color get neutralForeground1Pressed => applyOverride(
    FluentColorToken.neutralForeground1Pressed,
    neutralForeground1,
  );

  /// Upstream `colorNeutralForeground1Selected`.
  Color get neutralForeground1Selected => applyOverride(
    FluentColorToken.neutralForeground1Selected,
    neutralForeground1,
  );

  /// Upstream `colorNeutralForeground2`.
  Color get neutralForeground2 =>
      applyOverride(FluentColorToken.neutralForeground2, _d ? _g(84) : _g(26));

  /// Upstream `colorNeutralForeground2Hover`.
  Color get neutralForeground2Hover => applyOverride(
    FluentColorToken.neutralForeground2Hover,
    _d ? _white : _g(14),
  );

  /// Upstream `colorNeutralForeground2Pressed`.
  Color get neutralForeground2Pressed => applyOverride(
    FluentColorToken.neutralForeground2Pressed,
    neutralForeground2Hover,
  );

  /// Upstream `colorNeutralForeground2Selected`.
  Color get neutralForeground2Selected => applyOverride(
    FluentColorToken.neutralForeground2Selected,
    neutralForeground2Hover,
  );

  /// Upstream `colorNeutralForeground2BrandHover`.
  Color get neutralForeground2BrandHover => applyOverride(
    FluentColorToken.neutralForeground2BrandHover,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorNeutralForeground2BrandPressed`.
  Color get neutralForeground2BrandPressed => applyOverride(
    FluentColorToken.neutralForeground2BrandPressed,
    _d ? brand[90] : brand[70],
  );

  /// Upstream `colorNeutralForeground2BrandSelected`.
  Color get neutralForeground2BrandSelected => applyOverride(
    FluentColorToken.neutralForeground2BrandSelected,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorNeutralForeground3`.
  Color get neutralForeground3 =>
      applyOverride(FluentColorToken.neutralForeground3, _d ? _g(68) : _g(38));

  /// Upstream `colorNeutralForeground3Hover`.
  Color get neutralForeground3Hover => applyOverride(
    FluentColorToken.neutralForeground3Hover,
    _d ? _g(84) : _g(26),
  );

  /// Upstream `colorNeutralForeground3Pressed`.
  Color get neutralForeground3Pressed => applyOverride(
    FluentColorToken.neutralForeground3Pressed,
    neutralForeground3Hover,
  );

  /// Upstream `colorNeutralForeground3Selected`.
  Color get neutralForeground3Selected => applyOverride(
    FluentColorToken.neutralForeground3Selected,
    neutralForeground3Hover,
  );

  /// Upstream `colorNeutralForeground3BrandHover`.
  Color get neutralForeground3BrandHover => applyOverride(
    FluentColorToken.neutralForeground3BrandHover,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorNeutralForeground3BrandPressed`.
  Color get neutralForeground3BrandPressed => applyOverride(
    FluentColorToken.neutralForeground3BrandPressed,
    _d ? brand[90] : brand[70],
  );

  /// Upstream `colorNeutralForeground3BrandSelected`.
  Color get neutralForeground3BrandSelected => applyOverride(
    FluentColorToken.neutralForeground3BrandSelected,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorNeutralForeground4`.
  Color get neutralForeground4 =>
      applyOverride(FluentColorToken.neutralForeground4, _d ? _g(60) : _g(44));

  /// Upstream `colorNeutralForeground5`.
  Color get neutralForeground5 =>
      applyOverride(FluentColorToken.neutralForeground5, _d ? _g(68) : _g(38));

  /// Upstream `colorNeutralForeground5Hover`.
  Color get neutralForeground5Hover => applyOverride(
    FluentColorToken.neutralForeground5Hover,
    _d ? _white : _g(14),
  );

  /// Upstream `colorNeutralForeground5Pressed`.
  Color get neutralForeground5Pressed => applyOverride(
    FluentColorToken.neutralForeground5Pressed,
    neutralForeground5Hover,
  );

  /// Upstream `colorNeutralForeground5Selected`.
  Color get neutralForeground5Selected => applyOverride(
    FluentColorToken.neutralForeground5Selected,
    neutralForeground5Hover,
  );

  /// Upstream `colorNeutralForegroundDisabled`.
  Color get neutralForegroundDisabled => applyOverride(
    FluentColorToken.neutralForegroundDisabled,
    _d ? _g(36) : _g(74),
  );

  /// Upstream `colorNeutralForegroundInvertedDisabled`.
  Color get neutralForegroundInvertedDisabled => applyOverride(
    FluentColorToken.neutralForegroundInvertedDisabled,
    const Color.fromRGBO(255, 255, 255, 0.4),
  );

  /// Upstream `colorNeutralForeground1Static`.
  Color get neutralForeground1Static =>
      applyOverride(FluentColorToken.neutralForeground1Static, _g(14));

  /// Upstream `colorNeutralForegroundStaticInverted`.
  Color get neutralForegroundStaticInverted =>
      applyOverride(FluentColorToken.neutralForegroundStaticInverted, _white);

  /// Upstream `colorNeutralForegroundInverted`.
  Color get neutralForegroundInverted => applyOverride(
    FluentColorToken.neutralForegroundInverted,
    _d ? _g(14) : _white,
  );

  /// Upstream `colorNeutralForegroundInvertedHover`.
  Color get neutralForegroundInvertedHover => applyOverride(
    FluentColorToken.neutralForegroundInvertedHover,
    neutralForegroundInverted,
  );

  /// Upstream `colorNeutralForegroundInvertedPressed`.
  Color get neutralForegroundInvertedPressed => applyOverride(
    FluentColorToken.neutralForegroundInvertedPressed,
    neutralForegroundInverted,
  );

  /// Upstream `colorNeutralForegroundInvertedSelected`.
  Color get neutralForegroundInvertedSelected => applyOverride(
    FluentColorToken.neutralForegroundInvertedSelected,
    neutralForegroundInverted,
  );

  /// Upstream `colorNeutralForegroundInverted2`.
  Color get neutralForegroundInverted2 => applyOverride(
    FluentColorToken.neutralForegroundInverted2,
    neutralForegroundInverted,
  );

  /// Upstream `colorNeutralForegroundOnBrand`.
  Color get neutralForegroundOnBrand =>
      applyOverride(FluentColorToken.neutralForegroundOnBrand, _white);

  /// Upstream `colorNeutralForegroundInvertedLink`.
  Color get neutralForegroundInvertedLink =>
      applyOverride(FluentColorToken.neutralForegroundInvertedLink, _white);

  /// Upstream `colorNeutralForegroundInvertedLinkHover`.
  Color get neutralForegroundInvertedLinkHover => applyOverride(
    FluentColorToken.neutralForegroundInvertedLinkHover,
    _white,
  );

  /// Upstream `colorNeutralForegroundInvertedLinkPressed`.
  Color get neutralForegroundInvertedLinkPressed => applyOverride(
    FluentColorToken.neutralForegroundInvertedLinkPressed,
    _white,
  );

  /// Upstream `colorNeutralForegroundInvertedLinkSelected`.
  Color get neutralForegroundInvertedLinkSelected => applyOverride(
    FluentColorToken.neutralForegroundInvertedLinkSelected,
    _white,
  );

  // --------------------------------------------------------------- brand text
  /// Upstream `colorBrandForegroundLink`.
  Color get brandForegroundLink => applyOverride(
    FluentColorToken.brandForegroundLink,
    _d ? brand[100] : brand[70],
  );

  /// Upstream `colorBrandForegroundLinkHover`.
  Color get brandForegroundLinkHover => applyOverride(
    FluentColorToken.brandForegroundLinkHover,
    _d ? brand[110] : brand[60],
  );

  /// Upstream `colorBrandForegroundLinkPressed`.
  Color get brandForegroundLinkPressed => applyOverride(
    FluentColorToken.brandForegroundLinkPressed,
    _d ? brand[90] : brand[40],
  );

  /// Upstream `colorBrandForegroundLinkSelected`.
  Color get brandForegroundLinkSelected => applyOverride(
    FluentColorToken.brandForegroundLinkSelected,
    _d ? brand[100] : brand[70],
  );

  /// Upstream `colorNeutralForeground2Link`.
  Color get neutralForeground2Link => applyOverride(
    FluentColorToken.neutralForeground2Link,
    _d ? _g(84) : _g(26),
  );

  /// Upstream `colorNeutralForeground2LinkHover`.
  Color get neutralForeground2LinkHover => applyOverride(
    FluentColorToken.neutralForeground2LinkHover,
    _d ? _white : _g(14),
  );

  /// Upstream `colorNeutralForeground2LinkPressed`.
  Color get neutralForeground2LinkPressed => applyOverride(
    FluentColorToken.neutralForeground2LinkPressed,
    neutralForeground2LinkHover,
  );

  /// Upstream `colorNeutralForeground2LinkSelected`.
  Color get neutralForeground2LinkSelected => applyOverride(
    FluentColorToken.neutralForeground2LinkSelected,
    neutralForeground2LinkHover,
  );

  /// Upstream `colorCompoundBrandForeground1`.
  Color get compoundBrandForeground1 => applyOverride(
    FluentColorToken.compoundBrandForeground1,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorCompoundBrandForeground1Hover`.
  Color get compoundBrandForeground1Hover => applyOverride(
    FluentColorToken.compoundBrandForeground1Hover,
    _d ? brand[110] : brand[70],
  );

  /// Upstream `colorCompoundBrandForeground1Pressed`.
  Color get compoundBrandForeground1Pressed => applyOverride(
    FluentColorToken.compoundBrandForeground1Pressed,
    _d ? brand[90] : brand[60],
  );

  /// Upstream `colorBrandForeground1`.
  Color get brandForeground1 => applyOverride(
    FluentColorToken.brandForeground1,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorBrandForeground2`.
  Color get brandForeground2 => applyOverride(
    FluentColorToken.brandForeground2,
    _d ? brand[110] : brand[70],
  );

  /// Upstream `colorBrandForeground2Hover`.
  Color get brandForeground2Hover => applyOverride(
    FluentColorToken.brandForeground2Hover,
    _d ? brand[130] : brand[60],
  );

  /// Upstream `colorBrandForeground2Pressed`.
  Color get brandForeground2Pressed => applyOverride(
    FluentColorToken.brandForeground2Pressed,
    _d ? brand[160] : brand[30],
  );

  /// Upstream `colorBrandForegroundInverted`.
  Color get brandForegroundInverted => applyOverride(
    FluentColorToken.brandForegroundInverted,
    _d ? brand[80] : brand[100],
  );

  /// Upstream `colorBrandForegroundInvertedHover`.
  Color get brandForegroundInvertedHover => applyOverride(
    FluentColorToken.brandForegroundInvertedHover,
    _d ? brand[70] : brand[110],
  );

  /// Upstream `colorBrandForegroundInvertedPressed`.
  Color get brandForegroundInvertedPressed => applyOverride(
    FluentColorToken.brandForegroundInvertedPressed,
    _d ? brand[60] : brand[100],
  );

  /// Upstream `colorBrandForegroundOnLight`.
  Color get brandForegroundOnLight =>
      applyOverride(FluentColorToken.brandForegroundOnLight, brand[80]);

  /// Upstream `colorBrandForegroundOnLightHover`.
  Color get brandForegroundOnLightHover =>
      applyOverride(FluentColorToken.brandForegroundOnLightHover, brand[70]);

  /// Upstream `colorBrandForegroundOnLightPressed`.
  Color get brandForegroundOnLightPressed =>
      applyOverride(FluentColorToken.brandForegroundOnLightPressed, brand[50]);

  /// Upstream `colorBrandForegroundOnLightSelected`.
  Color get brandForegroundOnLightSelected =>
      applyOverride(FluentColorToken.brandForegroundOnLightSelected, brand[60]);

  // --------------------------------------------------------------- background
  /// Upstream `colorNeutralBackground1`.
  Color get neutralBackground1 =>
      applyOverride(FluentColorToken.neutralBackground1, _d ? _g(16) : _white);

  /// Upstream `colorNeutralBackground1Hover`.
  Color get neutralBackground1Hover => applyOverride(
    FluentColorToken.neutralBackground1Hover,
    _d ? _g(24) : _g(96),
  );

  /// Upstream `colorNeutralBackground1Pressed`.
  Color get neutralBackground1Pressed => applyOverride(
    FluentColorToken.neutralBackground1Pressed,
    _d ? _g(12) : _g(88),
  );

  /// Upstream `colorNeutralBackground1Selected`.
  Color get neutralBackground1Selected => applyOverride(
    FluentColorToken.neutralBackground1Selected,
    _d ? _g(22) : _g(92),
  );

  /// Upstream `colorNeutralBackground2`.
  Color get neutralBackground2 =>
      applyOverride(FluentColorToken.neutralBackground2, _d ? _g(12) : _g(98));

  /// Upstream `colorNeutralBackground2Hover`.
  Color get neutralBackground2Hover => applyOverride(
    FluentColorToken.neutralBackground2Hover,
    _d ? _g(20) : _g(94),
  );

  /// Upstream `colorNeutralBackground2Pressed`.
  Color get neutralBackground2Pressed => applyOverride(
    FluentColorToken.neutralBackground2Pressed,
    _d ? _g(8) : _g(86),
  );

  /// Upstream `colorNeutralBackground2Selected`.
  Color get neutralBackground2Selected => applyOverride(
    FluentColorToken.neutralBackground2Selected,
    _d ? _g(18) : _g(90),
  );

  /// Upstream `colorNeutralBackground3`.
  Color get neutralBackground3 =>
      applyOverride(FluentColorToken.neutralBackground3, _d ? _g(8) : _g(96));

  /// Upstream `colorNeutralBackground3Hover`.
  Color get neutralBackground3Hover => applyOverride(
    FluentColorToken.neutralBackground3Hover,
    _d ? _g(16) : _g(92),
  );

  /// Upstream `colorNeutralBackground3Pressed`.
  Color get neutralBackground3Pressed => applyOverride(
    FluentColorToken.neutralBackground3Pressed,
    _d ? _g(4) : _g(84),
  );

  /// Upstream `colorNeutralBackground3Selected`.
  Color get neutralBackground3Selected => applyOverride(
    FluentColorToken.neutralBackground3Selected,
    _d ? _g(14) : _g(88),
  );

  /// Upstream `colorNeutralBackground4`.
  Color get neutralBackground4 =>
      applyOverride(FluentColorToken.neutralBackground4, _d ? _g(4) : _g(94));

  /// Upstream `colorNeutralBackground4Hover`.
  Color get neutralBackground4Hover => applyOverride(
    FluentColorToken.neutralBackground4Hover,
    _d ? _g(12) : _g(98),
  );

  /// Upstream `colorNeutralBackground4Pressed`.
  Color get neutralBackground4Pressed => applyOverride(
    FluentColorToken.neutralBackground4Pressed,
    _d ? _black : _g(96),
  );

  /// Upstream `colorNeutralBackground4Selected`.
  Color get neutralBackground4Selected => applyOverride(
    FluentColorToken.neutralBackground4Selected,
    _d ? _g(10) : _white,
  );

  /// Upstream `colorNeutralBackground5`.
  Color get neutralBackground5 =>
      applyOverride(FluentColorToken.neutralBackground5, _d ? _black : _g(92));

  /// Upstream `colorNeutralBackground5Hover`.
  Color get neutralBackground5Hover => applyOverride(
    FluentColorToken.neutralBackground5Hover,
    _d ? _g(8) : _g(96),
  );

  /// Upstream `colorNeutralBackground5Pressed`.
  Color get neutralBackground5Pressed => applyOverride(
    FluentColorToken.neutralBackground5Pressed,
    _d ? _g(2) : _g(94),
  );

  /// Upstream `colorNeutralBackground5Selected`.
  Color get neutralBackground5Selected => applyOverride(
    FluentColorToken.neutralBackground5Selected,
    _d ? _g(6) : _g(98),
  );

  /// Upstream `colorNeutralBackground6`.
  Color get neutralBackground6 =>
      applyOverride(FluentColorToken.neutralBackground6, _d ? _g(20) : _g(90));

  /// Upstream `colorNeutralBackground7`.
  Color get neutralBackground7 =>
      applyOverride(FluentColorToken.neutralBackground7, _clear);

  /// Upstream `colorNeutralBackground7Hover`.
  Color get neutralBackground7Hover => applyOverride(
    FluentColorToken.neutralBackground7Hover,
    _d ? _g(10) : _g(92),
  );

  /// Upstream `colorNeutralBackground7Pressed`.
  Color get neutralBackground7Pressed => applyOverride(
    FluentColorToken.neutralBackground7Pressed,
    _d ? _g(4) : _g(84),
  );

  /// Upstream `colorNeutralBackground7Selected`.
  Color get neutralBackground7Selected =>
      applyOverride(FluentColorToken.neutralBackground7Selected, _clear);

  /// Upstream `colorNeutralBackground8`.
  Color get neutralBackground8 =>
      applyOverride(FluentColorToken.neutralBackground8, _d ? _g(16) : _g(99));

  /// Upstream `colorNeutralBackgroundInverted`.
  Color get neutralBackgroundInverted => applyOverride(
    FluentColorToken.neutralBackgroundInverted,
    _d ? _white : _g(16),
  );

  /// Upstream `colorNeutralBackgroundInvertedHover`.
  Color get neutralBackgroundInvertedHover => applyOverride(
    FluentColorToken.neutralBackgroundInvertedHover,
    _d ? _g(96) : _g(24),
  );

  /// Upstream `colorNeutralBackgroundInvertedPressed`.
  Color get neutralBackgroundInvertedPressed => applyOverride(
    FluentColorToken.neutralBackgroundInvertedPressed,
    _d ? _g(88) : _g(12),
  );

  /// Upstream `colorNeutralBackgroundInvertedSelected`.
  Color get neutralBackgroundInvertedSelected => applyOverride(
    FluentColorToken.neutralBackgroundInvertedSelected,
    _d ? _g(92) : _g(22),
  );

  /// Upstream `colorNeutralBackgroundStatic`.
  Color get neutralBackgroundStatic => applyOverride(
    FluentColorToken.neutralBackgroundStatic,
    _d ? _g(24) : _g(20),
  );

  /// Upstream `colorNeutralBackgroundAlpha`.
  Color get neutralBackgroundAlpha => applyOverride(
    FluentColorToken.neutralBackgroundAlpha,
    _d
        ? const Color.fromRGBO(26, 26, 26, 0.5)
        : const Color.fromRGBO(255, 255, 255, 0.5),
  );

  /// Upstream `colorNeutralBackgroundAlpha2`.
  Color get neutralBackgroundAlpha2 => applyOverride(
    FluentColorToken.neutralBackgroundAlpha2,
    _d
        ? const Color.fromRGBO(31, 31, 31, 0.7)
        : const Color.fromRGBO(255, 255, 255, 0.8),
  );

  /// Upstream `colorNeutralBackgroundDisabled`.
  Color get neutralBackgroundDisabled => applyOverride(
    FluentColorToken.neutralBackgroundDisabled,
    _d ? _g(8) : _g(94),
  );

  /// Upstream `colorNeutralBackgroundDisabled2`.
  Color get neutralBackgroundDisabled2 => applyOverride(
    FluentColorToken.neutralBackgroundDisabled2,
    _d ? _g(16) : _white,
  );

  /// Upstream `colorNeutralBackgroundInvertedDisabled`.
  Color get neutralBackgroundInvertedDisabled => applyOverride(
    FluentColorToken.neutralBackgroundInvertedDisabled,
    const Color.fromRGBO(255, 255, 255, 0.1),
  );

  /// Upstream `colorSubtleBackground`.
  Color get subtleBackground =>
      applyOverride(FluentColorToken.subtleBackground, _clear);

  /// Upstream `colorSubtleBackgroundHover`.
  Color get subtleBackgroundHover => applyOverride(
    FluentColorToken.subtleBackgroundHover,
    _d ? _g(22) : _g(96),
  );

  /// Upstream `colorSubtleBackgroundPressed`.
  Color get subtleBackgroundPressed => applyOverride(
    FluentColorToken.subtleBackgroundPressed,
    _d ? _g(18) : _g(88),
  );

  /// Upstream `colorSubtleBackgroundSelected`.
  Color get subtleBackgroundSelected => applyOverride(
    FluentColorToken.subtleBackgroundSelected,
    _d ? _g(20) : _g(92),
  );

  /// Upstream `colorSubtleBackgroundLightAlphaHover`.
  Color get subtleBackgroundLightAlphaHover => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaHover,
    _d
        ? const Color.fromRGBO(36, 36, 36, 0.8)
        : const Color.fromRGBO(255, 255, 255, 0.7),
  );

  /// Upstream `colorSubtleBackgroundLightAlphaPressed`.
  Color get subtleBackgroundLightAlphaPressed => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaPressed,
    _d
        ? const Color.fromRGBO(36, 36, 36, 0.5)
        : const Color.fromRGBO(255, 255, 255, 0.5),
  );

  /// Upstream `colorSubtleBackgroundLightAlphaSelected`.
  Color get subtleBackgroundLightAlphaSelected => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaSelected,
    _clear,
  );

  /// Upstream `colorSubtleBackgroundInverted`.
  Color get subtleBackgroundInverted =>
      applyOverride(FluentColorToken.subtleBackgroundInverted, _clear);

  /// Upstream `colorSubtleBackgroundInvertedHover`.
  Color get subtleBackgroundInvertedHover => applyOverride(
    FluentColorToken.subtleBackgroundInvertedHover,
    const Color.fromRGBO(0, 0, 0, 0.1),
  );

  /// Upstream `colorSubtleBackgroundInvertedPressed`.
  Color get subtleBackgroundInvertedPressed => applyOverride(
    FluentColorToken.subtleBackgroundInvertedPressed,
    const Color.fromRGBO(0, 0, 0, 0.3),
  );

  /// Upstream `colorSubtleBackgroundInvertedSelected`.
  Color get subtleBackgroundInvertedSelected => applyOverride(
    FluentColorToken.subtleBackgroundInvertedSelected,
    const Color.fromRGBO(0, 0, 0, 0.2),
  );

  /// Upstream `colorTransparentBackground`.
  Color get transparentBackground =>
      applyOverride(FluentColorToken.transparentBackground, _clear);

  /// Upstream `colorTransparentBackgroundHover`.
  Color get transparentBackgroundHover =>
      applyOverride(FluentColorToken.transparentBackgroundHover, _clear);

  /// Upstream `colorTransparentBackgroundPressed`.
  Color get transparentBackgroundPressed =>
      applyOverride(FluentColorToken.transparentBackgroundPressed, _clear);

  /// Upstream `colorTransparentBackgroundSelected`.
  Color get transparentBackgroundSelected =>
      applyOverride(FluentColorToken.transparentBackgroundSelected, _clear);

  /// Upstream `colorNeutralStencil1`.
  Color get neutralStencil1 =>
      applyOverride(FluentColorToken.neutralStencil1, _d ? _g(34) : _g(90));

  /// Upstream `colorNeutralStencil2`.
  Color get neutralStencil2 =>
      applyOverride(FluentColorToken.neutralStencil2, _d ? _g(20) : _g(98));

  /// Upstream `colorNeutralStencil1Alpha`.
  Color get neutralStencil1Alpha => applyOverride(
    FluentColorToken.neutralStencil1Alpha,
    _d
        ? const Color.fromRGBO(255, 255, 255, 0.1)
        : const Color.fromRGBO(0, 0, 0, 0.1),
  );

  /// Upstream `colorNeutralStencil2Alpha`.
  Color get neutralStencil2Alpha => applyOverride(
    FluentColorToken.neutralStencil2Alpha,
    _d
        ? const Color.fromRGBO(255, 255, 255, 0.05)
        : const Color.fromRGBO(0, 0, 0, 0.05),
  );

  /// Upstream `colorBackgroundOverlay`.
  Color get backgroundOverlay => applyOverride(
    FluentColorToken.backgroundOverlay,
    Color.fromRGBO(0, 0, 0, _d ? 0.5 : 0.4),
  );

  /// Upstream `colorScrollbarOverlay`.
  Color get scrollbarOverlay => applyOverride(
    FluentColorToken.scrollbarOverlay,
    _d
        ? const Color.fromRGBO(255, 255, 255, 0.6)
        : const Color.fromRGBO(0, 0, 0, 0.5),
  );

  // --------------------------------------------------------- brand background
  /// Upstream `colorBrandBackground`.
  Color get brandBackground => applyOverride(
    FluentColorToken.brandBackground,
    _d ? brand[70] : brand[80],
  );

  /// Upstream `colorBrandBackgroundHover`.
  Color get brandBackgroundHover => applyOverride(
    FluentColorToken.brandBackgroundHover,
    _d ? brand[80] : brand[70],
  );

  /// Upstream `colorBrandBackgroundPressed`.
  Color get brandBackgroundPressed =>
      applyOverride(FluentColorToken.brandBackgroundPressed, brand[40]);

  /// Upstream `colorBrandBackgroundSelected`.
  Color get brandBackgroundSelected =>
      applyOverride(FluentColorToken.brandBackgroundSelected, brand[60]);

  /// Upstream `colorCompoundBrandBackground`.
  Color get compoundBrandBackground => applyOverride(
    FluentColorToken.compoundBrandBackground,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorCompoundBrandBackgroundHover`.
  Color get compoundBrandBackgroundHover => applyOverride(
    FluentColorToken.compoundBrandBackgroundHover,
    _d ? brand[110] : brand[70],
  );

  /// Upstream `colorCompoundBrandBackgroundPressed`.
  Color get compoundBrandBackgroundPressed => applyOverride(
    FluentColorToken.compoundBrandBackgroundPressed,
    _d ? brand[90] : brand[60],
  );

  /// Upstream `colorBrandBackgroundStatic`.
  Color get brandBackgroundStatic =>
      applyOverride(FluentColorToken.brandBackgroundStatic, brand[80]);

  /// Upstream `colorBrandBackground2`.
  Color get brandBackground2 => applyOverride(
    FluentColorToken.brandBackground2,
    _d ? brand[20] : brand[160],
  );

  /// Upstream `colorBrandBackground2Hover`.
  Color get brandBackground2Hover => applyOverride(
    FluentColorToken.brandBackground2Hover,
    _d ? brand[40] : brand[150],
  );

  /// Upstream `colorBrandBackground2Pressed`.
  Color get brandBackground2Pressed => applyOverride(
    FluentColorToken.brandBackground2Pressed,
    _d ? brand[10] : brand[130],
  );

  /// Upstream `colorBrandBackground3Static`.
  Color get brandBackground3Static =>
      applyOverride(FluentColorToken.brandBackground3Static, brand[60]);

  /// Upstream `colorBrandBackground4Static`.
  Color get brandBackground4Static =>
      applyOverride(FluentColorToken.brandBackground4Static, brand[40]);

  /// Upstream `colorBrandBackgroundInverted`.
  Color get brandBackgroundInverted =>
      applyOverride(FluentColorToken.brandBackgroundInverted, _white);

  /// Upstream `colorBrandBackgroundInvertedHover`.
  Color get brandBackgroundInvertedHover =>
      applyOverride(FluentColorToken.brandBackgroundInvertedHover, brand[160]);

  /// Upstream `colorBrandBackgroundInvertedPressed`.
  Color get brandBackgroundInvertedPressed => applyOverride(
    FluentColorToken.brandBackgroundInvertedPressed,
    brand[140],
  );

  /// Upstream `colorBrandBackgroundInvertedSelected`.
  Color get brandBackgroundInvertedSelected => applyOverride(
    FluentColorToken.brandBackgroundInvertedSelected,
    brand[150],
  );

  // ---------------------------------------------------------------- card
  /// Upstream `colorNeutralCardBackground`.
  Color get neutralCardBackground => applyOverride(
    FluentColorToken.neutralCardBackground,
    _d ? _g(20) : _g(98),
  );

  /// Upstream `colorNeutralCardBackgroundHover`.
  Color get neutralCardBackgroundHover => applyOverride(
    FluentColorToken.neutralCardBackgroundHover,
    _d ? _g(24) : _white,
  );

  /// Upstream `colorNeutralCardBackgroundPressed`.
  Color get neutralCardBackgroundPressed => applyOverride(
    FluentColorToken.neutralCardBackgroundPressed,
    _d ? _g(18) : _g(96),
  );

  /// Upstream `colorNeutralCardBackgroundSelected`.
  Color get neutralCardBackgroundSelected => applyOverride(
    FluentColorToken.neutralCardBackgroundSelected,
    _d ? _g(22) : _g(92),
  );

  /// Upstream `colorNeutralCardBackgroundDisabled`.
  Color get neutralCardBackgroundDisabled => applyOverride(
    FluentColorToken.neutralCardBackgroundDisabled,
    _d ? _g(8) : _g(94),
  );

  // ---------------------------------------------------------------- stroke
  /// Upstream `colorNeutralStrokeAccessible`.
  Color get neutralStrokeAccessible => applyOverride(
    FluentColorToken.neutralStrokeAccessible,
    _d ? _g(68) : _g(38),
  );

  /// Upstream `colorNeutralStrokeAccessibleHover`.
  Color get neutralStrokeAccessibleHover => applyOverride(
    FluentColorToken.neutralStrokeAccessibleHover,
    _d ? _g(74) : _g(34),
  );

  /// Upstream `colorNeutralStrokeAccessiblePressed`.
  Color get neutralStrokeAccessiblePressed => applyOverride(
    FluentColorToken.neutralStrokeAccessiblePressed,
    _d ? _g(70) : _g(30),
  );

  /// Upstream `colorNeutralStrokeAccessibleSelected`.
  Color get neutralStrokeAccessibleSelected => applyOverride(
    FluentColorToken.neutralStrokeAccessibleSelected,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorNeutralStroke1`.
  Color get neutralStroke1 =>
      applyOverride(FluentColorToken.neutralStroke1, _d ? _g(40) : _g(82));

  /// Upstream `colorNeutralStroke1Hover`.
  Color get neutralStroke1Hover =>
      applyOverride(FluentColorToken.neutralStroke1Hover, _d ? _g(46) : _g(78));

  /// Upstream `colorNeutralStroke1Pressed`.
  Color get neutralStroke1Pressed => applyOverride(
    FluentColorToken.neutralStroke1Pressed,
    _d ? _g(42) : _g(70),
  );

  /// Upstream `colorNeutralStroke1Selected`.
  Color get neutralStroke1Selected => applyOverride(
    FluentColorToken.neutralStroke1Selected,
    _d ? _g(44) : _g(74),
  );

  /// Upstream `colorNeutralStroke2`.
  Color get neutralStroke2 =>
      applyOverride(FluentColorToken.neutralStroke2, _d ? _g(32) : _g(88));

  /// Upstream `colorNeutralStroke3`.
  Color get neutralStroke3 =>
      applyOverride(FluentColorToken.neutralStroke3, _d ? _g(24) : _g(94));

  /// Upstream `colorNeutralStroke4`.
  Color get neutralStroke4 =>
      applyOverride(FluentColorToken.neutralStroke4, _d ? _g(24) : _g(92));

  /// Upstream `colorNeutralStroke4Hover`.
  Color get neutralStroke4Hover =>
      applyOverride(FluentColorToken.neutralStroke4Hover, _d ? _g(18) : _g(88));

  /// Upstream `colorNeutralStroke4Pressed`.
  Color get neutralStroke4Pressed => applyOverride(
    FluentColorToken.neutralStroke4Pressed,
    _d ? _g(14) : _g(84),
  );

  /// Upstream `colorNeutralStroke4Selected`.
  Color get neutralStroke4Selected => applyOverride(
    FluentColorToken.neutralStroke4Selected,
    _d ? _g(24) : _g(92),
  );

  /// Upstream `colorNeutralStrokeSubtle`.
  Color get neutralStrokeSubtle =>
      applyOverride(FluentColorToken.neutralStrokeSubtle, _d ? _g(4) : _g(88));

  /// Upstream `colorNeutralStrokeOnBrand`.
  Color get neutralStrokeOnBrand => applyOverride(
    FluentColorToken.neutralStrokeOnBrand,
    _d ? _g(16) : _white,
  );

  /// Upstream `colorNeutralStrokeOnBrand2`.
  Color get neutralStrokeOnBrand2 =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2, _white);

  /// Upstream `colorNeutralStrokeOnBrand2Hover`.
  Color get neutralStrokeOnBrand2Hover =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Hover, _white);

  /// Upstream `colorNeutralStrokeOnBrand2Pressed`.
  Color get neutralStrokeOnBrand2Pressed =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Pressed, _white);

  /// Upstream `colorNeutralStrokeOnBrand2Selected`.
  Color get neutralStrokeOnBrand2Selected =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Selected, _white);

  /// Upstream `colorBrandStroke1`.
  Color get brandStroke1 =>
      applyOverride(FluentColorToken.brandStroke1, _d ? brand[100] : brand[80]);

  /// Upstream `colorBrandStroke2`.
  Color get brandStroke2 =>
      applyOverride(FluentColorToken.brandStroke2, _d ? brand[50] : brand[140]);

  /// Upstream `colorBrandStroke2Hover`.
  Color get brandStroke2Hover => applyOverride(
    FluentColorToken.brandStroke2Hover,
    _d ? brand[50] : brand[120],
  );

  /// Upstream `colorBrandStroke2Pressed`.
  Color get brandStroke2Pressed => applyOverride(
    FluentColorToken.brandStroke2Pressed,
    _d ? brand[30] : brand[80],
  );

  /// Upstream `colorBrandStroke2Contrast`.
  Color get brandStroke2Contrast => applyOverride(
    FluentColorToken.brandStroke2Contrast,
    _d ? brand[50] : brand[140],
  );

  /// Upstream `colorCompoundBrandStroke`.
  Color get compoundBrandStroke => applyOverride(
    FluentColorToken.compoundBrandStroke,
    _d ? brand[100] : brand[80],
  );

  /// Upstream `colorCompoundBrandStrokeHover`.
  Color get compoundBrandStrokeHover => applyOverride(
    FluentColorToken.compoundBrandStrokeHover,
    _d ? brand[110] : brand[70],
  );

  /// Upstream `colorCompoundBrandStrokePressed`.
  Color get compoundBrandStrokePressed => applyOverride(
    FluentColorToken.compoundBrandStrokePressed,
    _d ? brand[90] : brand[60],
  );

  /// Upstream `colorNeutralStrokeDisabled`.
  Color get neutralStrokeDisabled => applyOverride(
    FluentColorToken.neutralStrokeDisabled,
    _d ? _g(26) : _g(88),
  );

  /// Upstream `colorNeutralStrokeDisabled2`.
  Color get neutralStrokeDisabled2 => applyOverride(
    FluentColorToken.neutralStrokeDisabled2,
    _d ? _g(24) : _g(92),
  );

  /// Upstream `colorNeutralStrokeInvertedDisabled`.
  Color get neutralStrokeInvertedDisabled => applyOverride(
    FluentColorToken.neutralStrokeInvertedDisabled,
    const Color.fromRGBO(255, 255, 255, 0.4),
  );

  /// Upstream `colorTransparentStroke`.
  Color get transparentStroke =>
      applyOverride(FluentColorToken.transparentStroke, _clear);

  /// Upstream `colorTransparentStrokeInteractive`.
  Color get transparentStrokeInteractive =>
      applyOverride(FluentColorToken.transparentStrokeInteractive, _clear);

  /// Upstream `colorTransparentStrokeDisabled`.
  Color get transparentStrokeDisabled =>
      applyOverride(FluentColorToken.transparentStrokeDisabled, _clear);

  /// Upstream `colorNeutralStrokeAlpha`.
  Color get neutralStrokeAlpha => applyOverride(
    FluentColorToken.neutralStrokeAlpha,
    _d
        ? const Color.fromRGBO(255, 255, 255, 0.1)
        : const Color.fromRGBO(0, 0, 0, 0.05),
  );

  /// Upstream `colorNeutralStrokeAlpha2`.
  Color get neutralStrokeAlpha2 => applyOverride(
    FluentColorToken.neutralStrokeAlpha2,
    const Color.fromRGBO(255, 255, 255, 0.2),
  );

  /// Fluent draws a two-tone focus ring: [strokeFocus1] inner, [strokeFocus2]
  /// outer. Both are needed — a single ring fails contrast on one theme.
  Color get strokeFocus1 =>
      applyOverride(FluentColorToken.strokeFocus1, _d ? _black : _white);

  /// Upstream `colorStrokeFocus2`.
  Color get strokeFocus2 =>
      applyOverride(FluentColorToken.strokeFocus2, _d ? _white : _black);

  // ---------------------------------------------------------------- shadow
  /// Upstream `colorNeutralShadowAmbient`.
  Color get neutralShadowAmbient => applyOverride(
    FluentColorToken.neutralShadowAmbient,
    Color.fromRGBO(0, 0, 0, _d ? 0.24 : 0.12),
  );

  /// Upstream `colorNeutralShadowKey`.
  Color get neutralShadowKey => applyOverride(
    FluentColorToken.neutralShadowKey,
    Color.fromRGBO(0, 0, 0, _d ? 0.28 : 0.14),
  );

  /// Upstream `colorNeutralShadowAmbientLighter`.
  Color get neutralShadowAmbientLighter => applyOverride(
    FluentColorToken.neutralShadowAmbientLighter,
    Color.fromRGBO(0, 0, 0, _d ? 0.12 : 0.06),
  );

  /// Upstream `colorNeutralShadowKeyLighter`.
  Color get neutralShadowKeyLighter => applyOverride(
    FluentColorToken.neutralShadowKeyLighter,
    Color.fromRGBO(0, 0, 0, _d ? 0.14 : 0.07),
  );

  /// Upstream `colorNeutralShadowAmbientDarker`.
  Color get neutralShadowAmbientDarker => applyOverride(
    FluentColorToken.neutralShadowAmbientDarker,
    Color.fromRGBO(0, 0, 0, _d ? 0.40 : 0.20),
  );

  /// Upstream `colorNeutralShadowKeyDarker`.
  Color get neutralShadowKeyDarker => applyOverride(
    FluentColorToken.neutralShadowKeyDarker,
    Color.fromRGBO(0, 0, 0, _d ? 0.48 : 0.24),
  );

  /// Upstream `colorBrandShadowAmbient`.
  Color get brandShadowAmbient => applyOverride(
    FluentColorToken.brandShadowAmbient,
    const Color.fromRGBO(0, 0, 0, 0.30),
  );

  /// Upstream `colorBrandShadowKey`.
  Color get brandShadowKey => applyOverride(
    FluentColorToken.brandShadowKey,
    const Color.fromRGBO(0, 0, 0, 0.25),
  );

  // ---------------------------------------------------------------- status
  /// Upstream `colorStatusDangerBackground1`.
  Color get statusDangerBackground1 => applyOverride(
    FluentColorToken.statusDangerBackground1,
    _d ? const Color(0xFF3B0509) : const Color(0xFFFDF3F4),
  );

  /// Upstream `colorStatusDangerBackground2`.
  Color get statusDangerBackground2 => applyOverride(
    FluentColorToken.statusDangerBackground2,
    _d ? const Color(0xFF6E0811) : const Color(0xFFEEACB2),
  );

  /// Upstream `colorStatusDangerBackground3`.
  Color get statusDangerBackground3 => applyOverride(
    FluentColorToken.statusDangerBackground3,
    const Color(0xFFC50F1F),
  );

  /// Upstream `colorStatusDangerBackground3Hover`.
  Color get statusDangerBackground3Hover => applyOverride(
    FluentColorToken.statusDangerBackground3Hover,
    const Color(0xFFB10E1C),
  );

  /// Upstream `colorStatusDangerBackground3Pressed`.
  Color get statusDangerBackground3Pressed => applyOverride(
    FluentColorToken.statusDangerBackground3Pressed,
    const Color(0xFF960B18),
  );

  /// Upstream `colorStatusDangerForeground1`.
  Color get statusDangerForeground1 => applyOverride(
    FluentColorToken.statusDangerForeground1,
    _d ? const Color(0xFFDC626D) : const Color(0xFFB10E1C),
  );

  /// Upstream `colorStatusDangerForeground2`.
  Color get statusDangerForeground2 => applyOverride(
    FluentColorToken.statusDangerForeground2,
    _d ? const Color(0xFFEEACB2) : const Color(0xFF6E0811),
  );

  /// Upstream `colorStatusDangerForeground3`.
  Color get statusDangerForeground3 => applyOverride(
    FluentColorToken.statusDangerForeground3,
    _d ? const Color(0xFFEEACB2) : const Color(0xFFC50F1F),
  );

  /// Upstream `colorStatusDangerForegroundInverted`.
  Color get statusDangerForegroundInverted => applyOverride(
    FluentColorToken.statusDangerForegroundInverted,
    _d ? const Color(0xFFB10E1C) : const Color(0xFFDC626D),
  );

  /// Upstream `colorStatusDangerBorderActive`.
  Color get statusDangerBorderActive => applyOverride(
    FluentColorToken.statusDangerBorderActive,
    _d ? const Color(0xFFDC626D) : const Color(0xFFC50F1F),
  );

  /// Upstream `colorStatusDangerBorder1`.
  Color get statusDangerBorder1 => applyOverride(
    FluentColorToken.statusDangerBorder1,
    _d ? const Color(0xFFC50F1F) : const Color(0xFFEEACB2),
  );

  /// Upstream `colorStatusDangerBorder2`.
  Color get statusDangerBorder2 => applyOverride(
    FluentColorToken.statusDangerBorder2,
    _d ? const Color(0xFFDC626D) : const Color(0xFFC50F1F),
  );

  /// Upstream `colorStatusSuccessBackground1`.
  Color get statusSuccessBackground1 => applyOverride(
    FluentColorToken.statusSuccessBackground1,
    _d ? const Color(0xFF052505) : const Color(0xFFF1FAF1),
  );

  /// Upstream `colorStatusSuccessBackground2`.
  Color get statusSuccessBackground2 => applyOverride(
    FluentColorToken.statusSuccessBackground2,
    _d ? const Color(0xFF094509) : const Color(0xFF9FD89F),
  );

  /// Upstream `colorStatusSuccessBackground3`.
  Color get statusSuccessBackground3 => applyOverride(
    FluentColorToken.statusSuccessBackground3,
    const Color(0xFF107C10),
  );

  /// Upstream `colorStatusSuccessForeground1`.
  Color get statusSuccessForeground1 => applyOverride(
    FluentColorToken.statusSuccessForeground1,
    _d ? const Color(0xFF54B054) : const Color(0xFF0E700E),
  );

  /// Upstream `colorStatusSuccessForeground2`.
  Color get statusSuccessForeground2 => applyOverride(
    FluentColorToken.statusSuccessForeground2,
    _d ? const Color(0xFF9FD89F) : const Color(0xFF094509),
  );

  /// Upstream `colorStatusSuccessForeground3`.
  Color get statusSuccessForeground3 => applyOverride(
    FluentColorToken.statusSuccessForeground3,
    _d ? const Color(0xFF9FD89F) : const Color(0xFF107C10),
  );

  /// Upstream `colorStatusSuccessForegroundInverted`.
  Color get statusSuccessForegroundInverted => applyOverride(
    FluentColorToken.statusSuccessForegroundInverted,
    _d ? const Color(0xFF107C10) : const Color(0xFF359B35),
  );

  /// Upstream `colorStatusSuccessBorderActive`.
  Color get statusSuccessBorderActive => applyOverride(
    FluentColorToken.statusSuccessBorderActive,
    _d ? const Color(0xFF54B054) : const Color(0xFF107C10),
  );

  /// Upstream `colorStatusSuccessBorder1`.
  Color get statusSuccessBorder1 => applyOverride(
    FluentColorToken.statusSuccessBorder1,
    _d ? const Color(0xFF107C10) : const Color(0xFF9FD89F),
  );

  /// Upstream `colorStatusSuccessBorder2`.
  Color get statusSuccessBorder2 => applyOverride(
    FluentColorToken.statusSuccessBorder2,
    _d ? const Color(0xFF9FD89F) : const Color(0xFF107C10),
  );

  /// Upstream `colorStatusWarningBackground1`.
  Color get statusWarningBackground1 => applyOverride(
    FluentColorToken.statusWarningBackground1,
    _d ? const Color(0xFF4A1E04) : const Color(0xFFFFF9F5),
  );

  /// Upstream `colorStatusWarningBackground2`.
  Color get statusWarningBackground2 => applyOverride(
    FluentColorToken.statusWarningBackground2,
    _d ? const Color(0xFF8A3707) : const Color(0xFFFDCFB4),
  );

  /// Upstream `colorStatusWarningBackground3`.
  Color get statusWarningBackground3 => applyOverride(
    FluentColorToken.statusWarningBackground3,
    const Color(0xFFF7630C),
  );

  /// Upstream `colorStatusWarningForeground1`.
  Color get statusWarningForeground1 => applyOverride(
    FluentColorToken.statusWarningForeground1,
    _d ? const Color(0xFFF98845) : const Color(0xFFBC4B09),
  );

  /// Upstream `colorStatusWarningForeground2`.
  Color get statusWarningForeground2 => applyOverride(
    FluentColorToken.statusWarningForeground2,
    _d ? const Color(0xFFFDCFB4) : const Color(0xFF8A3707),
  );

  /// Upstream `colorStatusWarningForeground3`.
  Color get statusWarningForeground3 => applyOverride(
    FluentColorToken.statusWarningForeground3,
    _d ? const Color(0xFFFDCFB4) : const Color(0xFFBC4B09),
  );

  /// Upstream `colorStatusWarningForegroundInverted`.
  Color get statusWarningForegroundInverted => applyOverride(
    FluentColorToken.statusWarningForegroundInverted,
    _d ? const Color(0xFFBC4B09) : const Color(0xFFFAA06B),
  );

  /// Upstream `colorStatusWarningBorderActive`.
  Color get statusWarningBorderActive => applyOverride(
    FluentColorToken.statusWarningBorderActive,
    _d ? const Color(0xFFFAA06B) : const Color(0xFFF7630C),
  );

  /// Upstream `colorStatusWarningBorder1`.
  Color get statusWarningBorder1 => applyOverride(
    FluentColorToken.statusWarningBorder1,
    _d ? const Color(0xFFDE590B) : const Color(0xFFFDCFB4),
  );

  /// Upstream `colorStatusWarningBorder2`.
  Color get statusWarningBorder2 => applyOverride(
    FluentColorToken.statusWarningBorder2,
    _d ? const Color(0xFFF98845) : const Color(0xFFBC4B09),
  );

  // ------------------------------------------------- severe and presence
  // Absent from upstream React, which has no colorStatusSevere* and files
  // presence colours on the PresenceBadge component instead. Sourced from the
  // Figma Status/* variables and placed here, on the alias layer, so they are
  // overridable through FluentColorToken like every other token.
  /// Figma `Status/*` only — React has no `colorStatusSevereBackground1`.
  Color get statusSevereBackground1 => applyOverride(
    FluentColorToken.statusSevereBackground1,
    _d ? const Color(0xFF411200) : const Color(0xFFFDF6F3),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereBackground2`.
  Color get statusSevereBackground2 => applyOverride(
    FluentColorToken.statusSevereBackground2,
    _d ? const Color(0xFF7A2101) : const Color(0xFFF4BFAB),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereBackground3`.
  Color get statusSevereBackground3 => applyOverride(
    FluentColorToken.statusSevereBackground3,
    const Color(0xFFDA3B01),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereForeground1`.
  Color get statusSevereForeground1 => applyOverride(
    FluentColorToken.statusSevereForeground1,
    _d ? const Color(0xFFE36537) : const Color(0xFFA62D01),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereForeground2`.
  Color get statusSevereForeground2 => applyOverride(
    FluentColorToken.statusSevereForeground2,
    _d ? const Color(0xFFF4BFAB) : const Color(0xFFA62D01),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereForeground3`.
  Color get statusSevereForeground3 => applyOverride(
    FluentColorToken.statusSevereForeground3,
    _d ? const Color(0xFFF4BFAB) : const Color(0xFFA62D01),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereForegroundInverted`.
  Color get statusSevereForegroundInverted => applyOverride(
    FluentColorToken.statusSevereForegroundInverted,
    _d ? const Color(0xFFA62D01) : const Color(0xFFE9835E),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereBorder1`.
  Color get statusSevereBorder1 => applyOverride(
    FluentColorToken.statusSevereBorder1,
    _d ? const Color(0xFFC43501) : const Color(0xFFF4BFAB),
  );

  /// Figma `Status/*` only — React has no `colorStatusSevereBorder2`.
  Color get statusSevereBorder2 => applyOverride(
    FluentColorToken.statusSevereBorder2,
    _d ? const Color(0xFFE36537) : const Color(0xFFA62D01),
  );

  /// Figma `Status/*` only — React has no `colorStatusAvailableForeground3`.
  Color get statusAvailableForeground3 => applyOverride(
    FluentColorToken.statusAvailableForeground3,
    const Color(0xFF13A10E),
  );

  /// Figma `Status/*` only — React has no `colorStatusAwayBackground3`.
  Color get statusAwayBackground3 => applyOverride(
    FluentColorToken.statusAwayBackground3,
    const Color(0xFFEAA300),
  );

  /// Figma `Status/*` only — React has no `colorStatusOofForeground3`.
  Color get statusOofForeground3 => applyOverride(
    FluentColorToken.statusOofForeground3,
    _d ? const Color(0xFFD161C4) : const Color(0xFFC239B3),
  );

  @override
  bool operator ==(Object other) =>
      other is FluentColors &&
      other.runtimeType == runtimeType &&
      other.brightness == brightness &&
      other.brand == brand &&
      _sameOverrides(other.overrides, overrides);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    brightness,
    brand,
    // Map has no structural hashCode. Length plus the unordered key set keeps
    // unequal palettes apart without depending on insertion order.
    overrides?.length ?? 0,
    Object.hashAllUnordered(overrides?.keys ?? const <FluentColorToken>[]),
  );

  static bool _sameOverrides(
    Map<FluentColorToken, Color>? a,
    Map<FluentColorToken, Color>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
