import 'dart:math' as math;

import 'js_math.dart';

// The three CSS component patterns from `d3-color/src/color.js:8-10`: an
// integer, a number and a percentage, each allowed to be surrounded by space.
const String _reI = r'\s*([+-]?\d+)\s*';
const String _reN = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)\s*';
const String _reP = r'\s*([+-]?(?:\d*\.)?\d+(?:[eE][+-]?\d+)?)%\s*';

// The seven specifier patterns, assembled exactly as `color.js:11-17` does.
final RegExp _reHex = RegExp(r'^#([0-9a-f]{3,8})$');
final RegExp _reRgbInteger = RegExp('^rgb\\($_reI,$_reI,$_reI\\)\$');
final RegExp _reRgbPercent = RegExp('^rgb\\($_reP,$_reP,$_reP\\)\$');
final RegExp _reRgbaInteger = RegExp('^rgba\\($_reI,$_reI,$_reI,$_reN\\)\$');
final RegExp _reRgbaPercent = RegExp('^rgba\\($_reP,$_reP,$_reP,$_reN\\)\$');
final RegExp _reHslPercent = RegExp('^hsl\\($_reN,$_reP,$_reP\\)\$');
final RegExp _reHslaPercent = RegExp('^hsla\\($_reN,$_reP,$_reP,$_reN\\)\$');

/// The 148 CSS named colours, transcribed verbatim and in source order from
/// `d3-color/src/color.js:19-168`.
///
/// The table is reachable: Plotly and Vega-Lite schemas may name a colour, and
/// `PlotlyColorAdapter.ts:152` parses whatever string arrives. `transparent` is
/// deliberately absent — upstream keeps it out of the table and handles it as a
/// separate case at `color.js:216`, because it is the one CSS keyword whose
/// channels are NaN rather than a hex triplet.
const Map<String, int> _named = <String, int>{
  'aliceblue': 0xf0f8ff,
  'antiquewhite': 0xfaebd7,
  'aqua': 0x00ffff,
  'aquamarine': 0x7fffd4,
  'azure': 0xf0ffff,
  'beige': 0xf5f5dc,
  'bisque': 0xffe4c4,
  'black': 0x000000,
  'blanchedalmond': 0xffebcd,
  'blue': 0x0000ff,
  'blueviolet': 0x8a2be2,
  'brown': 0xa52a2a,
  'burlywood': 0xdeb887,
  'cadetblue': 0x5f9ea0,
  'chartreuse': 0x7fff00,
  'chocolate': 0xd2691e,
  'coral': 0xff7f50,
  'cornflowerblue': 0x6495ed,
  'cornsilk': 0xfff8dc,
  'crimson': 0xdc143c,
  'cyan': 0x00ffff,
  'darkblue': 0x00008b,
  'darkcyan': 0x008b8b,
  'darkgoldenrod': 0xb8860b,
  'darkgray': 0xa9a9a9,
  'darkgreen': 0x006400,
  'darkgrey': 0xa9a9a9,
  'darkkhaki': 0xbdb76b,
  'darkmagenta': 0x8b008b,
  'darkolivegreen': 0x556b2f,
  'darkorange': 0xff8c00,
  'darkorchid': 0x9932cc,
  'darkred': 0x8b0000,
  'darksalmon': 0xe9967a,
  'darkseagreen': 0x8fbc8f,
  'darkslateblue': 0x483d8b,
  'darkslategray': 0x2f4f4f,
  'darkslategrey': 0x2f4f4f,
  'darkturquoise': 0x00ced1,
  'darkviolet': 0x9400d3,
  'deeppink': 0xff1493,
  'deepskyblue': 0x00bfff,
  'dimgray': 0x696969,
  'dimgrey': 0x696969,
  'dodgerblue': 0x1e90ff,
  'firebrick': 0xb22222,
  'floralwhite': 0xfffaf0,
  'forestgreen': 0x228b22,
  'fuchsia': 0xff00ff,
  'gainsboro': 0xdcdcdc,
  'ghostwhite': 0xf8f8ff,
  'gold': 0xffd700,
  'goldenrod': 0xdaa520,
  'gray': 0x808080,
  'green': 0x008000,
  'greenyellow': 0xadff2f,
  'grey': 0x808080,
  'honeydew': 0xf0fff0,
  'hotpink': 0xff69b4,
  'indianred': 0xcd5c5c,
  'indigo': 0x4b0082,
  'ivory': 0xfffff0,
  'khaki': 0xf0e68c,
  'lavender': 0xe6e6fa,
  'lavenderblush': 0xfff0f5,
  'lawngreen': 0x7cfc00,
  'lemonchiffon': 0xfffacd,
  'lightblue': 0xadd8e6,
  'lightcoral': 0xf08080,
  'lightcyan': 0xe0ffff,
  'lightgoldenrodyellow': 0xfafad2,
  'lightgray': 0xd3d3d3,
  'lightgreen': 0x90ee90,
  'lightgrey': 0xd3d3d3,
  'lightpink': 0xffb6c1,
  'lightsalmon': 0xffa07a,
  'lightseagreen': 0x20b2aa,
  'lightskyblue': 0x87cefa,
  'lightslategray': 0x778899,
  'lightslategrey': 0x778899,
  'lightsteelblue': 0xb0c4de,
  'lightyellow': 0xffffe0,
  'lime': 0x00ff00,
  'limegreen': 0x32cd32,
  'linen': 0xfaf0e6,
  'magenta': 0xff00ff,
  'maroon': 0x800000,
  'mediumaquamarine': 0x66cdaa,
  'mediumblue': 0x0000cd,
  'mediumorchid': 0xba55d3,
  'mediumpurple': 0x9370db,
  'mediumseagreen': 0x3cb371,
  'mediumslateblue': 0x7b68ee,
  'mediumspringgreen': 0x00fa9a,
  'mediumturquoise': 0x48d1cc,
  'mediumvioletred': 0xc71585,
  'midnightblue': 0x191970,
  'mintcream': 0xf5fffa,
  'mistyrose': 0xffe4e1,
  'moccasin': 0xffe4b5,
  'navajowhite': 0xffdead,
  'navy': 0x000080,
  'oldlace': 0xfdf5e6,
  'olive': 0x808000,
  'olivedrab': 0x6b8e23,
  'orange': 0xffa500,
  'orangered': 0xff4500,
  'orchid': 0xda70d6,
  'palegoldenrod': 0xeee8aa,
  'palegreen': 0x98fb98,
  'paleturquoise': 0xafeeee,
  'palevioletred': 0xdb7093,
  'papayawhip': 0xffefd5,
  'peachpuff': 0xffdab9,
  'peru': 0xcd853f,
  'pink': 0xffc0cb,
  'plum': 0xdda0dd,
  'powderblue': 0xb0e0e6,
  'purple': 0x800080,
  'rebeccapurple': 0x663399,
  'red': 0xff0000,
  'rosybrown': 0xbc8f8f,
  'royalblue': 0x4169e1,
  'saddlebrown': 0x8b4513,
  'salmon': 0xfa8072,
  'sandybrown': 0xf4a460,
  'seagreen': 0x2e8b57,
  'seashell': 0xfff5ee,
  'sienna': 0xa0522d,
  'silver': 0xc0c0c0,
  'skyblue': 0x87ceeb,
  'slateblue': 0x6a5acd,
  'slategray': 0x708090,
  'slategrey': 0x708090,
  'snow': 0xfffafa,
  'springgreen': 0x00ff7f,
  'steelblue': 0x4682b4,
  'tan': 0xd2b48c,
  'teal': 0x008080,
  'thistle': 0xd8bfd8,
  'tomato': 0xff6347,
  'turquoise': 0x40e0d0,
  'violet': 0xee82ee,
  'wheat': 0xf5deb3,
  'white': 0xffffff,
  'whitesmoke': 0xf5f5f5,
  'yellow': 0xffff00,
  'yellowgreen': 0x9acd32,
};

/// `d3-color/src/color.js:288-290`. NaN reads as fully opaque.
double _clampAlpha(double opacity) =>
    opacity.isNaN ? 1.0 : math.max(0.0, math.min(1.0, opacity));

/// `d3-color/src/color.js:292-294`. `Math.round(v) || 0` turns NaN into 0,
/// which is what makes `transparent` render as `rgba(0, 0, 0, 0)`.
int _clampInt(double value) {
  final rounded = jsRound(value);
  // `|| 0` also collapses -0 to 0, which `toInt()` would do anyway.
  final safe = rounded.isNaN ? 0.0 : rounded;
  // Clamping before `toInt()` rather than after is a deliberate reordering of
  // upstream's `Math.max(0, Math.min(255, …))`: the two agree on every finite
  // value, but `double.infinity.toInt()` throws in Dart where JS would clamp.
  // 0 and 255 are the sRGB channel bounds.
  return math.max(0.0, math.min(255.0, safe)).toInt();
}

/// One channel as two lower-case hex digits (`d3-color/src/color.js:296-299`).
String _hex2(double value) =>
    _clampInt(value).toRadixString(16).padLeft(2, '0');

/// A parsed CSS colour.
sealed class D3Color {
  /// Base constructor.
  const D3Color();

  /// This colour in the sRGB space (`d3-color/src/color.js:256`, `:354`).
  D3Rgb rgb();

  /// `#rrggbb` (`d3-color/src/color.js:276`).
  String formatHex() => rgb().formatHex();

  /// `#rrggbbaa` (`d3-color/src/color.js:280`).
  String formatHex8() => rgb().formatHex8();

  /// `rgb(r, g, b)`, or `rgba(r, g, b, a)` when the alpha is not 1
  /// (`d3-color/src/color.js:283-286`). This is also [toString].
  String formatRgb() => rgb().formatRgb();

  /// A copy with a different [opacity] (`d3-color/src/color.js:171-173`).
  D3Color copyWith({double? opacity});

  @override
  String toString() => formatRgb();
}

/// An sRGB colour with unclamped channels (`d3-color/src/color.js:240-245`).
final class D3Rgb extends D3Color {
  /// Creates a colour from raw channel values, which need not be in range —
  /// d3 clamps only when formatting.
  const D3Rgb(this.r, this.g, this.b, [this.a = 1.0]);

  /// Red, nominally 0–255.
  final double r;

  /// Green, nominally 0–255.
  final double g;

  /// Blue, nominally 0–255.
  final double b;

  /// Opacity, nominally 0–1.
  final double a;

  @override
  D3Rgb rgb() => this;

  @override
  String formatHex() => '#${_hex2(r)}${_hex2(g)}${_hex2(b)}';

  @override
  String formatHex8() =>
      // color.js:280 — an unset alpha formats as `ff`, not `00`. 255 scales the
      // 0–1 opacity to a byte.
      '#${_hex2(r)}${_hex2(g)}${_hex2(b)}${_hex2((a.isNaN ? 1.0 : a) * 255)}';

  @override
  String formatRgb() {
    final alpha = _clampAlpha(a);
    // color.js:284-285 — the functional notation gains its `a` only when the
    // colour is not fully opaque.
    final head = alpha == 1 ? 'rgb(' : 'rgba(';
    final tail = alpha == 1 ? ')' : ', ${jsNumberToString(alpha)})';
    return '$head${_clampInt(r)}, ${_clampInt(g)}, ${_clampInt(b)}$tail';
  }

  @override
  D3Rgb copyWith({double? opacity}) => D3Rgb(r, g, b, opacity ?? a);
}

/// An HSL colour (`d3-color/src/color.js:338-343`).
final class D3Hsl extends D3Color {
  /// Creates an HSL colour.
  const D3Hsl(this.h, this.s, this.l, [this.a = 1.0]);

  /// Hue in degrees; NaN for an achromatic colour.
  final double h;

  /// Saturation, 0–1.
  final double s;

  /// Lightness, 0–1.
  final double l;

  /// Opacity, 0–1.
  final double a;

  @override
  D3Rgb rgb() {
    // color.js:355-365, the FvD 13.37 / CSS Color Module Level 3 conversion.
    //
    // `remainder`, not `%`: JavaScript's `%` keeps the sign of the dividend, so
    // `-60 % 360` is -60 and the `+ 360` correction lands on 300. Dart's `%` is
    // always non-negative, which would turn `hsl(-60, 100%, 50%)` — magenta —
    // into a hue of 660 and a black swatch. `double.remainder` is the operator
    // with JavaScript's semantics. NaN survives both untouched.
    final hue = h.remainder(360) + (h < 0 ? 360 : 0);
    // color.js:356 — an undefined hue or saturation desaturates to grey.
    final sat = hue.isNaN || s.isNaN ? 0.0 : s;
    // color.js:358-359. 0.5 is the lightness at which the chroma peaks.
    final m2 = l + (l < 0.5 ? l : 1 - l) * sat;
    final m1 = 2 * l - m2;
    // 120 degrees apart on the wheel: red leads green, green leads blue.
    return D3Rgb(
      _hslToRgb(hue >= 240 ? hue - 240 : hue + 120, m1, m2),
      _hslToRgb(hue, m1, m2),
      _hslToRgb(hue < 120 ? hue + 240 : hue - 120, m1, m2),
      a,
    );
  }

  /// `d3-color/src/color.js:391-396`. The wheel is read in 60-degree sextants:
  /// rising to [m2] below 60, flat until 180, falling back to [m1] by 240.
  static double _hslToRgb(double h, double m1, double m2) {
    final v = h < 60
        ? m1 + (m2 - m1) * h / 60
        : h < 180
        ? m2
        : h < 240
        ? m1 + (m2 - m1) * (240 - h) / 60
        : m1;
    // 255 scales the unit interval to an sRGB channel.
    return v * 255;
  }

  @override
  D3Hsl copyWith({double? opacity}) => D3Hsl(h, s, l, opacity ?? a);
}

/// `d3-color/src/color.js:220-222`. Unpacks `0xrrggbb`.
D3Rgb _rgbFromInt(int n) => D3Rgb(
  ((n >> 16) & 0xff).toDouble(),
  ((n >> 8) & 0xff).toDouble(),
  (n & 0xff).toDouble(),
);

D3Rgb _rgba(double r, double g, double b, double a) =>
    // color.js:224-227 — a fully transparent colour loses its channels.
    a <= 0 ? D3Rgb(double.nan, double.nan, double.nan, a) : D3Rgb(r, g, b, a);

D3Hsl _hsla(double h, double s, double l, double a) {
  // color.js:301-306 — each degenerate case erases the channels that no longer
  // carry information, so that a round trip through RGB cannot invent a hue.
  if (a <= 0) {
    return D3Hsl(double.nan, double.nan, double.nan, a);
  }
  // Lightness at either extreme is black or white, whatever the hue.
  if (l <= 0 || l >= 1) {
    return D3Hsl(double.nan, double.nan, l, a);
  }
  if (s <= 0) {
    return D3Hsl(double.nan, s, l, a);
  }
  return D3Hsl(h, s, l, a);
}

/// A captured group as a double. JavaScript coerces the string implicitly at
/// `d3-color/src/color.js:209-214`; Dart has to say so.
double _p(String? group) => double.parse(group!);

/// Parses a CSS colour string (`d3-color/src/color.js:201-218`), returning
/// `null` when it is not one.
D3Color? color(String specifier) {
  final format = specifier.trim().toLowerCase();

  final hex = _reHex.firstMatch(format);
  if (hex != null) {
    final digits = hex.group(1)!;
    final n = int.parse(digits, radix: 16);
    // color.js:204-208. The digit count is the notation: 6 is `#rrggbb`, 3 is
    // `#rgb`, 8 adds an alpha byte and 4 a single alpha digit. 5 and 7 are
    // invalid.
    switch (digits.length) {
      case 6:
        return _rgbFromInt(n);
      case 3:
        // Each nibble is duplicated: `#f00` is `#ff0000`.
        return D3Rgb(
          (((n >> 8) & 0xf) | ((n >> 4) & 0xf0)).toDouble(),
          (((n >> 4) & 0xf) | (n & 0xf0)).toDouble(),
          (((n & 0xf) << 4) | (n & 0xf)).toDouble(),
        );
      case 8:
        return _rgba(
          ((n >> 24) & 0xff).toDouble(),
          ((n >> 16) & 0xff).toDouble(),
          ((n >> 8) & 0xff).toDouble(),
          // 0xff is the opaque byte, so the division normalises to 0–1.
          (n & 0xff) / 0xff,
        );
      case 4:
        return _rgba(
          (((n >> 12) & 0xf) | ((n >> 8) & 0xf0)).toDouble(),
          (((n >> 8) & 0xf) | ((n >> 4) & 0xf0)).toDouble(),
          (((n >> 4) & 0xf) | (n & 0xf0)).toDouble(),
          (((n & 0xf) << 4) | (n & 0xf)) / 0xff,
        );
      default:
        return null;
    }
  }

  var m = _reRgbInteger.firstMatch(format);
  if (m != null) {
    return D3Rgb(_p(m.group(1)), _p(m.group(2)), _p(m.group(3)));
  }
  m = _reRgbPercent.firstMatch(format);
  if (m != null) {
    // color.js:210. 255 / 100 turns a percentage into an sRGB channel.
    return D3Rgb(
      _p(m.group(1)) * 255 / 100,
      _p(m.group(2)) * 255 / 100,
      _p(m.group(3)) * 255 / 100,
    );
  }
  m = _reRgbaInteger.firstMatch(format);
  if (m != null) {
    return _rgba(
      _p(m.group(1)),
      _p(m.group(2)),
      _p(m.group(3)),
      _p(m.group(4)),
    );
  }
  m = _reRgbaPercent.firstMatch(format);
  if (m != null) {
    return _rgba(
      _p(m.group(1)) * 255 / 100,
      _p(m.group(2)) * 255 / 100,
      _p(m.group(3)) * 255 / 100,
      _p(m.group(4)),
    );
  }
  m = _reHslPercent.firstMatch(format);
  if (m != null) {
    // color.js:213 — the hue is degrees, the other two are percentages, and 1
    // is the implied opacity.
    return _hsla(_p(m.group(1)), _p(m.group(2)) / 100, _p(m.group(3)) / 100, 1);
  }
  m = _reHslaPercent.firstMatch(format);
  if (m != null) {
    return _hsla(
      _p(m.group(1)),
      _p(m.group(2)) / 100,
      _p(m.group(3)) / 100,
      _p(m.group(4)),
    );
  }

  final named = _named[format];
  if (named != null) {
    return _rgbFromInt(named);
  }
  // color.js:216 — the one keyword outside the table.
  if (format == 'transparent') {
    return const D3Rgb(double.nan, double.nan, double.nan, 0);
  }
  return null;
}

/// Converts [value] — a CSS string or a [D3Color] — to sRGB
/// (`d3-color/src/color.js:229-238`). Returns `null` when it does not parse.
D3Rgb? rgb(Object value) {
  if (value is D3Color) {
    return value.rgb();
  }
  final parsed = color(value as String);
  return parsed?.rgb();
}

/// Converts [value] — a CSS string or a [D3Color] — to HSL
/// (`d3-color/src/color.js:308-332`). Returns `null` when it does not parse.
D3Hsl? hsl(Object value) {
  final parsed = value is D3Color ? value : color(value as String);
  if (parsed == null) {
    return null;
  }
  // color.js:309,312 — a colour that is already HSL is returned as it stands.
  // Converting to sRGB and back would be lossy in exactly the cases `_hsla`
  // guards: `hsl(-60, 100%, 50%)` keeps its hue of -60 here, where the round
  // trip reports the equivalent 300.
  if (parsed is D3Hsl) {
    return parsed;
  }
  final asRgb = parsed.rgb();
  // color.js:314-316. 255 normalises each channel to the unit interval.
  final r = asRgb.r / 255;
  final g = asRgb.g / 255;
  final b = asRgb.b / 255;
  final lo = math.min(r, math.min(g, b));
  final hi = math.max(r, math.max(g, b));
  var h = double.nan;
  var s = hi - lo;
  final l = (hi + lo) / 2;
  // color.js:322 — `if (s)` is false for both 0 and NaN.
  if (s != 0 && !s.isNaN) {
    // color.js:323-325. The hue is measured in sextants from whichever channel
    // is the maximum; 6 wraps a negative red-sector hue back into range.
    if (r == hi) {
      h = (g - b) / s + (g < b ? 6 : 0);
    } else if (g == hi) {
      h = (b - r) / s + 2;
    } else {
      h = (r - g) / s + 4;
    }
    // color.js:326 — the chroma is normalised against whichever end of the
    // lightness range it sits in. 0.5 is the midpoint, 2 the doubled maximum.
    s /= l < 0.5 ? hi + lo : 2 - hi - lo;
    // 60 degrees per sextant.
    h *= 60;
  } else {
    // color.js:329 — grey has no saturation, black and white have none defined.
    s = l > 0 && l < 1 ? 0 : h;
  }
  return D3Hsl(h, s, l, asRgb.a);
}
