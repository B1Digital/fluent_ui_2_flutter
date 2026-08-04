import 'package:flutter/widgets.dart';

import 'alias_colors.dart';
import 'color_token.dart';
import 'global_colors.dart';

/// Teams dark, which is *not* `FluentColors(brightness: dark)` with the Teams
/// brand — upstream generates it from `teamsDarkColor.ts`, which differs from
/// the standard dark table in exactly 20 tokens.
///
/// The layered backgrounds are shifted one step lighter and the compound-brand
/// stroke one step darker; everything else falls through to [FluentColors].
class FluentTeamsDarkColors extends FluentColors {
  /// Creates the Teams dark palette.
  const FluentTeamsDarkColors({
    super.brand = FluentBrandRamp.teams,
    super.overrides,
  }) : super(brightness: Brightness.dark);

  @override
  FluentTeamsDarkColors withOverrides(Map<FluentColorToken, Color> extra) =>
      FluentTeamsDarkColors(brand: brand, overrides: {...?overrides, ...extra});

  @override
  Color get brandForeground2 =>
      applyOverride(FluentColorToken.brandForeground2, brand[120]);

  @override
  Color get neutralBackground2 =>
      applyOverride(FluentColorToken.neutralBackground2, FluentGrey.at(14));
  @override
  Color get neutralBackground2Hover => applyOverride(
    FluentColorToken.neutralBackground2Hover,
    FluentGrey.at(22),
  );
  @override
  Color get neutralBackground2Pressed => applyOverride(
    FluentColorToken.neutralBackground2Pressed,
    FluentGrey.at(10),
  );
  @override
  Color get neutralBackground2Selected => applyOverride(
    FluentColorToken.neutralBackground2Selected,
    FluentGrey.at(20),
  );

  @override
  Color get neutralBackground3 =>
      applyOverride(FluentColorToken.neutralBackground3, FluentGrey.at(12));
  @override
  Color get neutralBackground3Hover => applyOverride(
    FluentColorToken.neutralBackground3Hover,
    FluentGrey.at(20),
  );
  @override
  Color get neutralBackground3Pressed => applyOverride(
    FluentColorToken.neutralBackground3Pressed,
    FluentGrey.at(8),
  );
  @override
  Color get neutralBackground3Selected => applyOverride(
    FluentColorToken.neutralBackground3Selected,
    FluentGrey.at(18),
  );

  @override
  Color get neutralBackground4 =>
      applyOverride(FluentColorToken.neutralBackground4, FluentGrey.at(8));
  @override
  Color get neutralBackground4Hover => applyOverride(
    FluentColorToken.neutralBackground4Hover,
    FluentGrey.at(16),
  );
  @override
  Color get neutralBackground4Pressed => applyOverride(
    FluentColorToken.neutralBackground4Pressed,
    FluentGrey.at(4),
  );
  @override
  Color get neutralBackground4Selected => applyOverride(
    FluentColorToken.neutralBackground4Selected,
    FluentGrey.at(14),
  );

  @override
  Color get neutralBackground5 =>
      applyOverride(FluentColorToken.neutralBackground5, FluentGrey.at(4));
  @override
  Color get neutralBackground5Hover => applyOverride(
    FluentColorToken.neutralBackground5Hover,
    FluentGrey.at(12),
  );
  @override
  Color get neutralBackground5Pressed => applyOverride(
    FluentColorToken.neutralBackground5Pressed,
    FluentGrey.black,
  );
  @override
  Color get neutralBackground5Selected => applyOverride(
    FluentColorToken.neutralBackground5Selected,
    FluentGrey.at(10),
  );

  @override
  Color get compoundBrandStroke =>
      applyOverride(FluentColorToken.compoundBrandStroke, brand[90]);
  @override
  Color get compoundBrandStrokeHover =>
      applyOverride(FluentColorToken.compoundBrandStrokeHover, brand[100]);
  @override
  Color get compoundBrandStrokePressed =>
      applyOverride(FluentColorToken.compoundBrandStrokePressed, brand[80]);
}

/// The high-contrast alias layer.
///
/// High contrast is a third mode, not a brightness: nearly every token collapses
/// onto eight Windows system colors, so hover/pressed states are signalled by
/// swapping to [FluentHighContrast.highlight] rather than by shading. Tokens
/// that are transparent in light and dark become opaque here — losing a border
/// is what breaks high-contrast users.
///
/// The brand ramp is deliberately ignored: high contrast has no brand color.
class FluentHighContrastColors extends FluentColors {
  /// Creates the high-contrast palette.
  const FluentHighContrastColors({super.overrides})
    : super(brightness: Brightness.dark);

  @override
  FluentHighContrastColors withOverrides(Map<FluentColorToken, Color> extra) =>
      FluentHighContrastColors(overrides: {...?overrides, ...extra});

  static const Color _text = FluentHighContrast.canvasText;
  static const Color _canvas = FluentHighContrast.canvas;
  static const Color _highlight = FluentHighContrast.highlight;
  static const Color _highlightText = FluentHighContrast.highlightText;
  static const Color _disabled = FluentHighContrast.disabled;
  static const Color _link = FluentHighContrast.hyperlink;
  static const Color _buttonText = FluentHighContrast.buttonText;
  static const Color _buttonFace = FluentHighContrast.buttonFace;

  // ---------------------------------------------------------------- foreground
  @override
  Color get neutralForeground1 =>
      applyOverride(FluentColorToken.neutralForeground1, _text);
  @override
  Color get neutralForeground1Hover =>
      applyOverride(FluentColorToken.neutralForeground1Hover, _highlightText);
  @override
  Color get neutralForeground1Pressed =>
      applyOverride(FluentColorToken.neutralForeground1Pressed, _highlightText);
  @override
  Color get neutralForeground1Selected => applyOverride(
    FluentColorToken.neutralForeground1Selected,
    _highlightText,
  );
  @override
  Color get neutralForeground2 =>
      applyOverride(FluentColorToken.neutralForeground2, _text);
  @override
  Color get neutralForeground2Hover =>
      applyOverride(FluentColorToken.neutralForeground2Hover, _highlightText);
  @override
  Color get neutralForeground2Pressed =>
      applyOverride(FluentColorToken.neutralForeground2Pressed, _highlightText);
  @override
  Color get neutralForeground2Selected => applyOverride(
    FluentColorToken.neutralForeground2Selected,
    _highlightText,
  );
  @override
  Color get neutralForeground2BrandHover => applyOverride(
    FluentColorToken.neutralForeground2BrandHover,
    _highlightText,
  );
  @override
  Color get neutralForeground2BrandPressed => applyOverride(
    FluentColorToken.neutralForeground2BrandPressed,
    _highlightText,
  );
  @override
  Color get neutralForeground2BrandSelected => applyOverride(
    FluentColorToken.neutralForeground2BrandSelected,
    _highlightText,
  );
  @override
  Color get neutralForeground3 =>
      applyOverride(FluentColorToken.neutralForeground3, _text);
  @override
  Color get neutralForeground3Hover =>
      applyOverride(FluentColorToken.neutralForeground3Hover, _highlightText);
  @override
  Color get neutralForeground3Pressed =>
      applyOverride(FluentColorToken.neutralForeground3Pressed, _highlightText);
  @override
  Color get neutralForeground3Selected => applyOverride(
    FluentColorToken.neutralForeground3Selected,
    _highlightText,
  );
  @override
  Color get neutralForeground3BrandHover => applyOverride(
    FluentColorToken.neutralForeground3BrandHover,
    _highlightText,
  );
  @override
  Color get neutralForeground3BrandPressed => applyOverride(
    FluentColorToken.neutralForeground3BrandPressed,
    _highlightText,
  );
  @override
  Color get neutralForeground3BrandSelected => applyOverride(
    FluentColorToken.neutralForeground3BrandSelected,
    _highlightText,
  );
  @override
  Color get neutralForeground4 =>
      applyOverride(FluentColorToken.neutralForeground4, _text);
  @override
  Color get neutralForeground5 =>
      applyOverride(FluentColorToken.neutralForeground5, _text);
  @override
  Color get neutralForeground5Hover =>
      applyOverride(FluentColorToken.neutralForeground5Hover, _highlightText);
  @override
  Color get neutralForeground5Pressed =>
      applyOverride(FluentColorToken.neutralForeground5Pressed, _highlightText);
  @override
  Color get neutralForeground5Selected => applyOverride(
    FluentColorToken.neutralForeground5Selected,
    _highlightText,
  );
  @override
  Color get neutralForegroundDisabled =>
      applyOverride(FluentColorToken.neutralForegroundDisabled, _disabled);
  @override
  Color get neutralForegroundInvertedDisabled => applyOverride(
    FluentColorToken.neutralForegroundInvertedDisabled,
    _disabled,
  );

  /// Canvas, not canvasText — the one place the generated table inverts.
  @override
  Color get neutralForeground1Static =>
      applyOverride(FluentColorToken.neutralForeground1Static, _canvas);
  @override
  Color get neutralForegroundStaticInverted =>
      applyOverride(FluentColorToken.neutralForegroundStaticInverted, _text);

  /// Canvas text, not `highlightText`.
  ///
  /// These four are painted on [neutralBackgroundInverted], which collapses to
  /// `canvas` in high contrast — and `highlightText` is `canvas`'s own colour,
  /// because it is the foreground for a *highlight* background, not this one.
  /// Mapping them to `highlightText` therefore painted black on black: every
  /// inverted surface (Tooltip, Popover, TeachingPopover) rendered its text
  /// invisible, outlined but empty.
  ///
  /// High contrast has no notion of an inverted surface — everything collapses
  /// onto the canvas pair — so the readable foreground here is `canvasText`.
  /// `neutralForegroundInvertedHover`, `...Pressed` and `...Selected` follow,
  /// since high contrast signals interaction by swapping to the system
  /// highlight rather than by shading a foreground.
  @override
  Color get neutralForegroundInverted =>
      applyOverride(FluentColorToken.neutralForegroundInverted, _text);
  @override
  Color get neutralForegroundInvertedHover =>
      applyOverride(FluentColorToken.neutralForegroundInvertedHover, _text);
  @override
  Color get neutralForegroundInvertedPressed =>
      applyOverride(FluentColorToken.neutralForegroundInvertedPressed, _text);
  @override
  Color get neutralForegroundInvertedSelected =>
      applyOverride(FluentColorToken.neutralForegroundInvertedSelected, _text);
  @override
  Color get neutralForegroundInverted2 =>
      applyOverride(FluentColorToken.neutralForegroundInverted2, _text);
  @override
  Color get neutralForegroundOnBrand =>
      applyOverride(FluentColorToken.neutralForegroundOnBrand, _buttonText);
  @override
  Color get neutralForegroundInvertedLink =>
      applyOverride(FluentColorToken.neutralForegroundInvertedLink, _link);
  @override
  Color get neutralForegroundInvertedLinkHover =>
      applyOverride(FluentColorToken.neutralForegroundInvertedLinkHover, _link);
  @override
  Color get neutralForegroundInvertedLinkPressed => applyOverride(
    FluentColorToken.neutralForegroundInvertedLinkPressed,
    _link,
  );
  @override
  Color get neutralForegroundInvertedLinkSelected => applyOverride(
    FluentColorToken.neutralForegroundInvertedLinkSelected,
    _link,
  );

  // ---------------------------------------------------------------- links
  @override
  Color get brandForegroundLink =>
      applyOverride(FluentColorToken.brandForegroundLink, _link);
  @override
  Color get brandForegroundLinkHover =>
      applyOverride(FluentColorToken.brandForegroundLinkHover, _link);
  @override
  Color get brandForegroundLinkPressed =>
      applyOverride(FluentColorToken.brandForegroundLinkPressed, _link);
  @override
  Color get brandForegroundLinkSelected =>
      applyOverride(FluentColorToken.brandForegroundLinkSelected, _link);
  @override
  Color get neutralForeground2Link =>
      applyOverride(FluentColorToken.neutralForeground2Link, _link);
  @override
  Color get neutralForeground2LinkHover =>
      applyOverride(FluentColorToken.neutralForeground2LinkHover, _link);
  @override
  Color get neutralForeground2LinkPressed =>
      applyOverride(FluentColorToken.neutralForeground2LinkPressed, _link);
  @override
  Color get neutralForeground2LinkSelected =>
      applyOverride(FluentColorToken.neutralForeground2LinkSelected, _link);

  // ---------------------------------------------------------------- brand text
  @override
  Color get compoundBrandForeground1 =>
      applyOverride(FluentColorToken.compoundBrandForeground1, _highlight);
  @override
  Color get compoundBrandForeground1Hover =>
      applyOverride(FluentColorToken.compoundBrandForeground1Hover, _highlight);
  @override
  Color get compoundBrandForeground1Pressed => applyOverride(
    FluentColorToken.compoundBrandForeground1Pressed,
    _highlight,
  );
  @override
  Color get brandForeground1 =>
      applyOverride(FluentColorToken.brandForeground1, _text);
  @override
  Color get brandForeground2 =>
      applyOverride(FluentColorToken.brandForeground2, _text);
  @override
  Color get brandForeground2Hover =>
      applyOverride(FluentColorToken.brandForeground2Hover, _text);
  @override
  Color get brandForeground2Pressed =>
      applyOverride(FluentColorToken.brandForeground2Pressed, _text);
  @override
  Color get brandForegroundInverted =>
      applyOverride(FluentColorToken.brandForegroundInverted, _text);
  @override
  Color get brandForegroundInvertedHover => applyOverride(
    FluentColorToken.brandForegroundInvertedHover,
    _highlightText,
  );
  @override
  Color get brandForegroundInvertedPressed => applyOverride(
    FluentColorToken.brandForegroundInvertedPressed,
    _highlightText,
  );
  @override
  Color get brandForegroundOnLight =>
      applyOverride(FluentColorToken.brandForegroundOnLight, _buttonText);
  @override
  Color get brandForegroundOnLightHover => applyOverride(
    FluentColorToken.brandForegroundOnLightHover,
    _highlightText,
  );
  @override
  Color get brandForegroundOnLightPressed => applyOverride(
    FluentColorToken.brandForegroundOnLightPressed,
    _highlightText,
  );
  @override
  Color get brandForegroundOnLightSelected => applyOverride(
    FluentColorToken.brandForegroundOnLightSelected,
    _highlightText,
  );

  // --------------------------------------------------------------- background
  @override
  Color get neutralBackground1 =>
      applyOverride(FluentColorToken.neutralBackground1, _canvas);
  @override
  Color get neutralBackground1Hover =>
      applyOverride(FluentColorToken.neutralBackground1Hover, _highlight);
  @override
  Color get neutralBackground1Pressed =>
      applyOverride(FluentColorToken.neutralBackground1Pressed, _highlight);
  @override
  Color get neutralBackground1Selected =>
      applyOverride(FluentColorToken.neutralBackground1Selected, _highlight);
  @override
  Color get neutralBackground2 =>
      applyOverride(FluentColorToken.neutralBackground2, _canvas);
  @override
  Color get neutralBackground2Hover =>
      applyOverride(FluentColorToken.neutralBackground2Hover, _highlight);
  @override
  Color get neutralBackground2Pressed =>
      applyOverride(FluentColorToken.neutralBackground2Pressed, _highlight);
  @override
  Color get neutralBackground2Selected =>
      applyOverride(FluentColorToken.neutralBackground2Selected, _highlight);
  @override
  Color get neutralBackground3 =>
      applyOverride(FluentColorToken.neutralBackground3, _canvas);
  @override
  Color get neutralBackground3Hover =>
      applyOverride(FluentColorToken.neutralBackground3Hover, _highlight);
  @override
  Color get neutralBackground3Pressed =>
      applyOverride(FluentColorToken.neutralBackground3Pressed, _highlight);
  @override
  Color get neutralBackground3Selected =>
      applyOverride(FluentColorToken.neutralBackground3Selected, _highlight);
  @override
  Color get neutralBackground4 =>
      applyOverride(FluentColorToken.neutralBackground4, _canvas);
  @override
  Color get neutralBackground4Hover =>
      applyOverride(FluentColorToken.neutralBackground4Hover, _highlight);
  @override
  Color get neutralBackground4Pressed =>
      applyOverride(FluentColorToken.neutralBackground4Pressed, _highlight);
  @override
  Color get neutralBackground4Selected =>
      applyOverride(FluentColorToken.neutralBackground4Selected, _highlight);
  @override
  Color get neutralBackground5 =>
      applyOverride(FluentColorToken.neutralBackground5, _canvas);
  @override
  Color get neutralBackground5Hover =>
      applyOverride(FluentColorToken.neutralBackground5Hover, _highlight);
  @override
  Color get neutralBackground5Pressed =>
      applyOverride(FluentColorToken.neutralBackground5Pressed, _highlight);
  @override
  Color get neutralBackground5Selected =>
      applyOverride(FluentColorToken.neutralBackground5Selected, _highlight);
  @override
  Color get neutralBackground6 =>
      applyOverride(FluentColorToken.neutralBackground6, _canvas);
  @override
  Color get neutralBackground7 =>
      applyOverride(FluentColorToken.neutralBackground7, _canvas);
  @override
  Color get neutralBackground7Hover =>
      applyOverride(FluentColorToken.neutralBackground7Hover, _highlight);
  @override
  Color get neutralBackground7Pressed =>
      applyOverride(FluentColorToken.neutralBackground7Pressed, _highlight);
  @override
  Color get neutralBackground7Selected =>
      applyOverride(FluentColorToken.neutralBackground7Selected, _highlight);
  @override
  Color get neutralBackground8 =>
      applyOverride(FluentColorToken.neutralBackground8, _canvas);
  @override
  Color get neutralBackgroundInverted =>
      applyOverride(FluentColorToken.neutralBackgroundInverted, _canvas);
  @override
  Color get neutralBackgroundInvertedHover => applyOverride(
    FluentColorToken.neutralBackgroundInvertedHover,
    _highlight,
  );
  @override
  Color get neutralBackgroundInvertedPressed => applyOverride(
    FluentColorToken.neutralBackgroundInvertedPressed,
    _highlight,
  );
  @override
  Color get neutralBackgroundInvertedSelected => applyOverride(
    FluentColorToken.neutralBackgroundInvertedSelected,
    _highlight,
  );
  @override
  Color get neutralBackgroundStatic =>
      applyOverride(FluentColorToken.neutralBackgroundStatic, _canvas);
  @override
  Color get neutralBackgroundAlpha =>
      applyOverride(FluentColorToken.neutralBackgroundAlpha, _canvas);
  @override
  Color get neutralBackgroundAlpha2 =>
      applyOverride(FluentColorToken.neutralBackgroundAlpha2, _canvas);
  @override
  Color get neutralBackgroundDisabled =>
      applyOverride(FluentColorToken.neutralBackgroundDisabled, _canvas);
  @override
  Color get neutralBackgroundDisabled2 =>
      applyOverride(FluentColorToken.neutralBackgroundDisabled2, _disabled);
  @override
  Color get neutralBackgroundInvertedDisabled => applyOverride(
    FluentColorToken.neutralBackgroundInvertedDisabled,
    _canvas,
  );

  @override
  Color get subtleBackgroundHover =>
      applyOverride(FluentColorToken.subtleBackgroundHover, _highlight);
  @override
  Color get subtleBackgroundPressed =>
      applyOverride(FluentColorToken.subtleBackgroundPressed, _highlight);
  @override
  Color get subtleBackgroundSelected =>
      applyOverride(FluentColorToken.subtleBackgroundSelected, _highlight);
  @override
  Color get subtleBackgroundLightAlphaHover => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaHover,
    _highlight,
  );
  @override
  Color get subtleBackgroundLightAlphaPressed => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaPressed,
    _highlight,
  );
  @override
  Color get subtleBackgroundLightAlphaSelected => applyOverride(
    FluentColorToken.subtleBackgroundLightAlphaSelected,
    _highlight,
  );
  @override
  Color get subtleBackgroundInvertedHover =>
      applyOverride(FluentColorToken.subtleBackgroundInvertedHover, _highlight);
  @override
  Color get subtleBackgroundInvertedPressed => applyOverride(
    FluentColorToken.subtleBackgroundInvertedPressed,
    _highlight,
  );
  @override
  Color get subtleBackgroundInvertedSelected => applyOverride(
    FluentColorToken.subtleBackgroundInvertedSelected,
    _highlight,
  );

  // Interactive states stay opaque in high contrast — a transparent hover
  // background would leave the state invisible.
  @override
  Color get transparentBackgroundHover =>
      applyOverride(FluentColorToken.transparentBackgroundHover, _highlight);
  @override
  Color get transparentBackgroundPressed =>
      applyOverride(FluentColorToken.transparentBackgroundPressed, _highlight);
  @override
  Color get transparentBackgroundSelected =>
      applyOverride(FluentColorToken.transparentBackgroundSelected, _highlight);

  @override
  Color get neutralStencil1 =>
      applyOverride(FluentColorToken.neutralStencil1, _text);
  @override
  Color get neutralStencil2 =>
      applyOverride(FluentColorToken.neutralStencil2, _text);
  @override
  Color get neutralStencil1Alpha =>
      applyOverride(FluentColorToken.neutralStencil1Alpha, _text);
  @override
  Color get neutralStencil2Alpha =>
      applyOverride(FluentColorToken.neutralStencil2Alpha, _text);
  @override
  Color get backgroundOverlay => applyOverride(
    FluentColorToken.backgroundOverlay,
    const Color.fromRGBO(0, 0, 0, 0.5),
  );
  @override
  Color get scrollbarOverlay =>
      applyOverride(FluentColorToken.scrollbarOverlay, _buttonFace);

  // --------------------------------------------------------- brand background
  @override
  Color get brandBackground =>
      applyOverride(FluentColorToken.brandBackground, _buttonFace);
  @override
  Color get brandBackgroundHover =>
      applyOverride(FluentColorToken.brandBackgroundHover, _highlight);
  @override
  Color get brandBackgroundPressed =>
      applyOverride(FluentColorToken.brandBackgroundPressed, _highlight);
  @override
  Color get brandBackgroundSelected =>
      applyOverride(FluentColorToken.brandBackgroundSelected, _highlight);
  @override
  Color get compoundBrandBackground =>
      applyOverride(FluentColorToken.compoundBrandBackground, _highlight);
  @override
  Color get compoundBrandBackgroundHover =>
      applyOverride(FluentColorToken.compoundBrandBackgroundHover, _highlight);
  @override
  Color get compoundBrandBackgroundPressed => applyOverride(
    FluentColorToken.compoundBrandBackgroundPressed,
    _highlight,
  );
  @override
  Color get brandBackgroundStatic =>
      applyOverride(FluentColorToken.brandBackgroundStatic, _canvas);
  @override
  Color get brandBackground2 =>
      applyOverride(FluentColorToken.brandBackground2, _canvas);
  @override
  Color get brandBackground2Hover =>
      applyOverride(FluentColorToken.brandBackground2Hover, _canvas);
  @override
  Color get brandBackground2Pressed =>
      applyOverride(FluentColorToken.brandBackground2Pressed, _canvas);
  @override
  Color get brandBackground3Static =>
      applyOverride(FluentColorToken.brandBackground3Static, _canvas);
  @override
  Color get brandBackground4Static =>
      applyOverride(FluentColorToken.brandBackground4Static, _canvas);
  @override
  Color get brandBackgroundInverted =>
      applyOverride(FluentColorToken.brandBackgroundInverted, _buttonFace);
  @override
  Color get brandBackgroundInvertedHover =>
      applyOverride(FluentColorToken.brandBackgroundInvertedHover, _highlight);
  @override
  Color get brandBackgroundInvertedPressed => applyOverride(
    FluentColorToken.brandBackgroundInvertedPressed,
    _highlight,
  );
  @override
  Color get brandBackgroundInvertedSelected => applyOverride(
    FluentColorToken.brandBackgroundInvertedSelected,
    _highlight,
  );

  // ---------------------------------------------------------------- card
  @override
  Color get neutralCardBackground =>
      applyOverride(FluentColorToken.neutralCardBackground, _canvas);
  @override
  Color get neutralCardBackgroundHover =>
      applyOverride(FluentColorToken.neutralCardBackgroundHover, _highlight);
  @override
  Color get neutralCardBackgroundPressed =>
      applyOverride(FluentColorToken.neutralCardBackgroundPressed, _highlight);
  @override
  Color get neutralCardBackgroundSelected =>
      applyOverride(FluentColorToken.neutralCardBackgroundSelected, _highlight);
  @override
  Color get neutralCardBackgroundDisabled =>
      applyOverride(FluentColorToken.neutralCardBackgroundDisabled, _canvas);

  // ---------------------------------------------------------------- stroke
  @override
  Color get neutralStrokeAccessible =>
      applyOverride(FluentColorToken.neutralStrokeAccessible, _text);
  @override
  Color get neutralStrokeAccessibleHover =>
      applyOverride(FluentColorToken.neutralStrokeAccessibleHover, _highlight);
  @override
  Color get neutralStrokeAccessiblePressed => applyOverride(
    FluentColorToken.neutralStrokeAccessiblePressed,
    _highlight,
  );
  @override
  Color get neutralStrokeAccessibleSelected => applyOverride(
    FluentColorToken.neutralStrokeAccessibleSelected,
    _highlight,
  );
  @override
  Color get neutralStroke1 =>
      applyOverride(FluentColorToken.neutralStroke1, _text);
  @override
  Color get neutralStroke1Hover =>
      applyOverride(FluentColorToken.neutralStroke1Hover, _highlight);
  @override
  Color get neutralStroke1Pressed =>
      applyOverride(FluentColorToken.neutralStroke1Pressed, _highlight);
  @override
  Color get neutralStroke1Selected =>
      applyOverride(FluentColorToken.neutralStroke1Selected, _highlight);
  @override
  Color get neutralStroke2 =>
      applyOverride(FluentColorToken.neutralStroke2, _text);
  @override
  Color get neutralStroke3 =>
      applyOverride(FluentColorToken.neutralStroke3, _text);
  @override
  Color get neutralStroke4 =>
      applyOverride(FluentColorToken.neutralStroke4, _text);
  @override
  Color get neutralStroke4Hover =>
      applyOverride(FluentColorToken.neutralStroke4Hover, _highlight);
  @override
  Color get neutralStroke4Pressed =>
      applyOverride(FluentColorToken.neutralStroke4Pressed, _highlight);
  @override
  Color get neutralStroke4Selected =>
      applyOverride(FluentColorToken.neutralStroke4Selected, _highlight);
  @override
  Color get neutralStrokeSubtle =>
      applyOverride(FluentColorToken.neutralStrokeSubtle, _text);
  @override
  Color get neutralStrokeOnBrand =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand, _canvas);
  @override
  Color get neutralStrokeOnBrand2 =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2, _text);
  @override
  Color get neutralStrokeOnBrand2Hover =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Hover, _text);
  @override
  Color get neutralStrokeOnBrand2Pressed =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Pressed, _text);
  @override
  Color get neutralStrokeOnBrand2Selected =>
      applyOverride(FluentColorToken.neutralStrokeOnBrand2Selected, _text);
  @override
  Color get brandStroke1 => applyOverride(FluentColorToken.brandStroke1, _text);
  @override
  Color get brandStroke2 => applyOverride(FluentColorToken.brandStroke2, _text);
  @override
  Color get brandStroke2Hover =>
      applyOverride(FluentColorToken.brandStroke2Hover, _highlight);
  @override
  Color get brandStroke2Pressed =>
      applyOverride(FluentColorToken.brandStroke2Pressed, _highlight);
  @override
  Color get brandStroke2Contrast =>
      applyOverride(FluentColorToken.brandStroke2Contrast, _canvas);
  @override
  Color get compoundBrandStroke =>
      applyOverride(FluentColorToken.compoundBrandStroke, _highlight);
  @override
  Color get compoundBrandStrokeHover =>
      applyOverride(FluentColorToken.compoundBrandStrokeHover, _highlight);
  @override
  Color get compoundBrandStrokePressed =>
      applyOverride(FluentColorToken.compoundBrandStrokePressed, _highlight);
  @override
  Color get neutralStrokeDisabled =>
      applyOverride(FluentColorToken.neutralStrokeDisabled, _disabled);
  @override
  Color get neutralStrokeDisabled2 =>
      applyOverride(FluentColorToken.neutralStrokeDisabled2, _disabled);
  @override
  Color get neutralStrokeInvertedDisabled =>
      applyOverride(FluentColorToken.neutralStrokeInvertedDisabled, _disabled);

  // Borders become visible rather than transparent — this is the whole point.
  @override
  Color get transparentStroke =>
      applyOverride(FluentColorToken.transparentStroke, _text);
  @override
  Color get transparentStrokeInteractive =>
      applyOverride(FluentColorToken.transparentStrokeInteractive, _highlight);
  @override
  Color get transparentStrokeDisabled =>
      applyOverride(FluentColorToken.transparentStrokeDisabled, _disabled);

  @override
  Color get neutralStrokeAlpha =>
      applyOverride(FluentColorToken.neutralStrokeAlpha, _text);
  @override
  Color get neutralStrokeAlpha2 =>
      applyOverride(FluentColorToken.neutralStrokeAlpha2, _canvas);
  @override
  Color get strokeFocus1 =>
      applyOverride(FluentColorToken.strokeFocus1, _canvas);
  @override
  Color get strokeFocus2 =>
      applyOverride(FluentColorToken.strokeFocus2, _highlight);

  // ---------------------------------------------------------------- status
  // Status colour is not available in high contrast; meaning must come from
  // text or iconography instead.
  @override
  Color get statusDangerBackground1 =>
      applyOverride(FluentColorToken.statusDangerBackground1, _canvas);
  @override
  Color get statusDangerBackground2 =>
      applyOverride(FluentColorToken.statusDangerBackground2, _canvas);
  @override
  Color get statusDangerBackground3 =>
      applyOverride(FluentColorToken.statusDangerBackground3, _text);
  @override
  Color get statusDangerBackground3Hover =>
      applyOverride(FluentColorToken.statusDangerBackground3Hover, _highlight);
  @override
  Color get statusDangerBackground3Pressed => applyOverride(
    FluentColorToken.statusDangerBackground3Pressed,
    _highlight,
  );
  @override
  Color get statusDangerForeground1 =>
      applyOverride(FluentColorToken.statusDangerForeground1, _text);
  @override
  Color get statusDangerForeground2 =>
      applyOverride(FluentColorToken.statusDangerForeground2, _text);
  @override
  Color get statusDangerForeground3 =>
      applyOverride(FluentColorToken.statusDangerForeground3, _text);
  @override
  Color get statusDangerForegroundInverted =>
      applyOverride(FluentColorToken.statusDangerForegroundInverted, _text);
  @override
  Color get statusDangerBorderActive =>
      applyOverride(FluentColorToken.statusDangerBorderActive, _highlight);
  @override
  Color get statusDangerBorder1 =>
      applyOverride(FluentColorToken.statusDangerBorder1, _text);
  @override
  Color get statusDangerBorder2 =>
      applyOverride(FluentColorToken.statusDangerBorder2, _text);

  @override
  Color get statusSuccessBackground1 =>
      applyOverride(FluentColorToken.statusSuccessBackground1, _canvas);
  @override
  Color get statusSuccessBackground2 =>
      applyOverride(FluentColorToken.statusSuccessBackground2, _canvas);
  @override
  Color get statusSuccessBackground3 =>
      applyOverride(FluentColorToken.statusSuccessBackground3, _text);
  @override
  Color get statusSuccessForeground1 =>
      applyOverride(FluentColorToken.statusSuccessForeground1, _text);
  @override
  Color get statusSuccessForeground2 =>
      applyOverride(FluentColorToken.statusSuccessForeground2, _text);
  @override
  Color get statusSuccessForeground3 =>
      applyOverride(FluentColorToken.statusSuccessForeground3, _text);
  @override
  Color get statusSuccessForegroundInverted =>
      applyOverride(FluentColorToken.statusSuccessForegroundInverted, _text);
  @override
  Color get statusSuccessBorderActive =>
      applyOverride(FluentColorToken.statusSuccessBorderActive, _highlight);
  @override
  Color get statusSuccessBorder1 =>
      applyOverride(FluentColorToken.statusSuccessBorder1, _text);
  @override
  Color get statusSuccessBorder2 =>
      applyOverride(FluentColorToken.statusSuccessBorder2, _text);

  @override
  Color get statusWarningBackground1 =>
      applyOverride(FluentColorToken.statusWarningBackground1, _canvas);
  @override
  Color get statusWarningBackground2 =>
      applyOverride(FluentColorToken.statusWarningBackground2, _canvas);
  @override
  Color get statusWarningBackground3 =>
      applyOverride(FluentColorToken.statusWarningBackground3, _text);
  @override
  Color get statusWarningForeground1 =>
      applyOverride(FluentColorToken.statusWarningForeground1, _text);
  @override
  Color get statusWarningForeground2 =>
      applyOverride(FluentColorToken.statusWarningForeground2, _text);
  @override
  Color get statusWarningForeground3 =>
      applyOverride(FluentColorToken.statusWarningForeground3, _text);
  @override
  Color get statusWarningForegroundInverted =>
      applyOverride(FluentColorToken.statusWarningForegroundInverted, _text);
  @override
  Color get statusWarningBorderActive =>
      applyOverride(FluentColorToken.statusWarningBorderActive, _highlight);
  @override
  Color get statusWarningBorder1 =>
      applyOverride(FluentColorToken.statusWarningBorder1, _text);
  @override
  Color get statusWarningBorder2 =>
      applyOverride(FluentColorToken.statusWarningBorder2, _text);
}
