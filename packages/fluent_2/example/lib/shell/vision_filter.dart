import 'dart:ui' show ColorFilter, ImageFilter;

/// The canvas toolbar's Vision simulator filters, the analogue of Storybook's
/// a11y addon (`addons/a11y/src/components/VisionSimulator.tsx`).
///
/// Upstream sets a CSS `filter` on the preview iframe: `blur(2px)` for blurred
/// vision, `grayscale(100%)` for grayscale, and `url('#<name>')` for the seven
/// colour-blindness simulations, each an SVG `feColorMatrix` the addon mounts
/// in a hidden `<svg>` (the `Bl` list and the `filter` elements in the
/// Storybook 9.1.17 `a11y` manager bundle). The order and the shares are that
/// list's; the names are lower case there and capitalised on screen by
/// `text-transform: capitalize`.
enum VisionFilter {
  /// CSS `blur(2px)`.
  blurredVision('Blurred Vision', '22.9%'),

  /// Weak green.
  deuteranomaly('Deuteranomaly', '2.7%'),

  /// No green.
  deuteranopia('Deuteranopia', '0.56%'),

  /// Weak red.
  protanomaly('Protanomaly', '0.66%'),

  /// No red.
  protanopia('Protanopia', '0.59%'),

  /// Weak blue.
  tritanomaly('Tritanomaly', '0.01%'),

  /// No blue.
  tritanopia('Tritanopia', '0.016%'),

  /// No colour at all, by Rec. 601 luma.
  achromatopsia('Achromatopsia', '0.0001%'),

  /// CSS `grayscale(100%)`. Upstream gives it no share.
  grayscale('Grayscale', null);

  const VisionFilter(this.label, this.share);

  /// The name the menu shows.
  final String label;

  /// The share of users upstream quotes, shown as "`share` of users"; null
  /// where the addon lists none.
  final String? share;

  /// The filter to paint the story through, for an `ImageFiltered`.
  ///
  /// - Blur: CSS `blur(<length>)` takes the Gaussian's standard deviation,
  ///   which is what [ImageFilter.blur]'s sigma is.
  /// - The seven matrices: the addon's `feColorMatrix` elements set no
  ///   `color-interpolation-filters`, so they run in SVG's default linearRGB.
  ///   Hence the sRGB → linear → matrix → sRGB sandwich, in one composed
  ///   filter so no 8-bit layer rounds the linear values in between.
  ///   Measured in headless Chrome 153 on #0078D4: protanopia gives #5151C3,
  ///   which this matches; the bare sRGB matrix would give #3435BE.
  /// - Grayscale: Chrome runs the CSS `grayscale()` function in sRGB, not
  ///   linearRGB — the same probe gives rgb(101, 101, 101), the Filter Effects
  ///   matrix on the sRGB values, where linearRGB would give 118 — so it is a
  ///   plain matrix.
  ImageFilter get imageFilter => switch (this) {
    VisionFilter.blurredVision => ImageFilter.blur(sigmaX: 2, sigmaY: 2),
    VisionFilter.grayscale => const ColorFilter.matrix(<double>[
      // Filter Effects 1, the `grayscale()` equivalent matrix at amount 1.
      .2126, .7152, .0722, 0, 0, //
      .2126, .7152, .0722, 0, 0, //
      .2126, .7152, .0722, 0, 0, //
      0, 0, 0, 1, 0, //
    ]),
    VisionFilter.protanopia => _linearRgb(<double>[
      .567, .433, 0, //
      .558, .442, 0, //
      0, .242, .758, //
    ]),
    VisionFilter.protanomaly => _linearRgb(<double>[
      .817, .183, 0, //
      .333, .667, 0, //
      0, .125, .875, //
    ]),
    VisionFilter.deuteranopia => _linearRgb(<double>[
      .625, .375, 0, //
      .7, .3, 0, //
      0, .3, .7, //
    ]),
    VisionFilter.deuteranomaly => _linearRgb(<double>[
      .8, .2, 0, //
      .258, .742, 0, //
      0, .142, .858, //
    ]),
    VisionFilter.tritanopia => _linearRgb(<double>[
      .95, .05, 0, //
      0, .433, .567, //
      0, .475, .525, //
    ]),
    VisionFilter.tritanomaly => _linearRgb(<double>[
      .967, .033, 0, //
      0, .733, .267, //
      0, .183, .817, //
    ]),
    VisionFilter.achromatopsia => _linearRgb(<double>[
      .299, .587, .114, //
      .299, .587, .114, //
      .299, .587, .114, //
    ]),
  };

  /// The addon's `feColorMatrix` for the 3x3 colour block [m] — each row with
  /// a zero alpha weight and a zero offset, then the identity alpha row —
  /// wrapped in the linearRGB round trip.
  static ImageFilter _linearRgb(List<double> m) => ImageFilter.compose(
    outer: const ColorFilter.linearToSrgbGamma(),
    inner: ImageFilter.compose(
      outer: ColorFilter.matrix(<double>[
        m[0], m[1], m[2], 0, 0, //
        m[3], m[4], m[5], 0, 0, //
        m[6], m[7], m[8], 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      inner: const ColorFilter.srgbToLinearGamma(),
    ),
  );
}
