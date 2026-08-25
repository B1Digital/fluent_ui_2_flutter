import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../d3/color.dart' as d3;
import '../data_viz_palette.dart';

/// `category10` translated to Fluent tokens
/// (`VegaLiteColorAdapter.ts:95-106`).
///
/// Positional: entry `n` replaces Vega's own `category10[n]`, whose hue the
/// trailing comment names.
const List<FluentDataVizToken> kVegaCategory10FluentMapping =
    <FluentDataVizToken>[
      FluentDataVizToken.color26, // blue -> lightBlue.shade10
      FluentDataVizToken.warning, // orange -> semantic warning
      FluentDataVizToken.color5, // green -> lightGreen.primary
      FluentDataVizToken.error, // red -> semantic error
      FluentDataVizToken.color4, // purple -> orchid.tint10
      FluentDataVizToken.color17, // brown -> pumpkin.shade20
      FluentDataVizToken.color22, // pink -> hotPink.tint20
      FluentDataVizToken.disabled, // grey -> semantic disabled
      FluentDataVizToken.color10, // olive -> gold.shade10
      FluentDataVizToken.color3, // cyan -> teal.tint20
    ];

/// `category20` translated to Fluent tokens
/// (`VegaLiteColorAdapter.ts:109-130`).
///
/// Ten hues, each followed by its light shade, in [kVegaCategory10FluentMapping]
/// order.
const List<FluentDataVizToken> kVegaCategory20FluentMapping =
    <FluentDataVizToken>[
      FluentDataVizToken.color26, FluentDataVizToken.color36, // blue
      FluentDataVizToken.warning, FluentDataVizToken.color27, // orange
      FluentDataVizToken.color5, FluentDataVizToken.color15, // green
      FluentDataVizToken.error, FluentDataVizToken.color32, // red
      FluentDataVizToken.color4, FluentDataVizToken.color24, // purple
      FluentDataVizToken.color17, FluentDataVizToken.color37, // brown
      FluentDataVizToken.color22, FluentDataVizToken.color12, // pink
      FluentDataVizToken.disabled, FluentDataVizToken.color31, // grey
      FluentDataVizToken.color10, FluentDataVizToken.color30, // olive
      FluentDataVizToken.color3, FluentDataVizToken.color13, // cyan
    ];

/// `tableau10` translated to Fluent tokens
/// (`VegaLiteColorAdapter.ts:133-144`).
const List<FluentDataVizToken> kVegaTableau10FluentMapping =
    <FluentDataVizToken>[
      FluentDataVizToken.color1, // blue -> cornflower.tint10
      FluentDataVizToken.color7, // orange -> pumpkin.primary
      FluentDataVizToken.error, // red -> semantic error
      FluentDataVizToken.color3, // teal -> teal.tint20
      FluentDataVizToken.color5, // green -> lightGreen.primary
      FluentDataVizToken.color10, // yellow -> gold.shade10
      FluentDataVizToken.color4, // purple -> orchid.tint10
      FluentDataVizToken.color2, // pink -> hotPink.primary
      FluentDataVizToken.color17, // brown -> pumpkin.shade20
      FluentDataVizToken.disabled, // grey -> semantic disabled
    ];

/// `tableau20` translated to Fluent tokens
/// (`VegaLiteColorAdapter.ts:147-168`).
///
/// The hue order differs from [kVegaTableau10FluentMapping] — green is third
/// here and fifth there — so the ten-colour mapping is not a prefix of this one.
const List<FluentDataVizToken> kVegaTableau20FluentMapping =
    <FluentDataVizToken>[
      FluentDataVizToken.color1, FluentDataVizToken.color11, // blue
      FluentDataVizToken.color7, FluentDataVizToken.color27, // orange
      FluentDataVizToken.color5, FluentDataVizToken.color15, // green
      FluentDataVizToken.color10, FluentDataVizToken.color30, // yellow
      FluentDataVizToken.color3, FluentDataVizToken.color13, // teal
      FluentDataVizToken.error, FluentDataVizToken.color32, // red
      FluentDataVizToken.disabled, FluentDataVizToken.color31, // grey
      FluentDataVizToken.color2, FluentDataVizToken.color12, // pink
      FluentDataVizToken.color4, FluentDataVizToken.color24, // purple
      FluentDataVizToken.color17, FluentDataVizToken.color37, // brown
    ];

/// The Fluent mapping for a scheme name, or null
/// (`VegaLiteColorAdapter.ts:192-224`).
///
/// `category20b` and `category20c` deliberately share `category20`'s mapping
/// (`:202-205`), and the eight ColorBrewer qualitative schemes at `:211-218`
/// return null so the default Fluent palette takes over — upstream's own
/// "not yet mapped" comment at `:219`. Those eight share the `default` arm's
/// behaviour exactly, so they are not spelled out here; the test names all
/// eight instead.
List<FluentDataVizToken>? _schemeMapping(String? scheme) {
  // `:193-195`. An empty string is falsy in JavaScript, so it takes this arm.
  if (scheme == null || scheme.isEmpty) {
    return null;
  }
  // `:197` lower-cases before the switch.
  switch (scheme.toLowerCase()) {
    case 'category10':
      return kVegaCategory10FluentMapping;
    case 'category20':
    case 'category20b':
    case 'category20c':
      return kVegaCategory20FluentMapping;
    case 'tableau10':
      return kVegaTableau10FluentMapping;
    case 'tableau20':
      return kVegaTableau20FluentMapping;
    default:
      return null;
  }
}

/// A palette entry as the lower-case `#rrggbb` string this adapter deals in.
///
/// `getColorFromToken` returns a CSS string upstream (`colors.ts:139-146`);
/// [FluentDataVizPalette] returns a Flutter [Color], and the Vega transformers
/// carry colours as strings all the way to the chart boundary. 255 scales
/// Flutter's 0–1 channels onto d3's 0–255 bytes, and `formatHex` rounds each
/// one with JavaScript's own half-up rule
/// (`d3-color/src/color.js:292-299`). The alpha is dropped because `formatHex`
/// drops it (`:276`) and every token is opaque. The Plotly adapter carries the
/// same two lines at `internal/plotly/color_adapter.dart:112-113`; they are not
/// shared, because one shared line would have to be public API for two private
/// callers.
String _hex(Color colour) =>
    d3.D3Rgb(colour.r * 255, colour.g * 255, colour.b * 255).formatHex();

/// The colour for series [index] (`VegaLiteColorAdapter.ts:235-255`).
///
/// Three priorities, in this order: an explicit [range] wins outright and is
/// cycled modulo its length; then a named [scheme] resolves through its Fluent
/// mapping; otherwise the qualitative cycle.
String getVegaColor(
  int index,
  String? scheme,
  List<String>? range, {
  required bool isDark,
}) {
  // `:242-244`. A consumer-supplied colour is returned verbatim and never
  // reaches the palette.
  if (range != null && range.isNotEmpty) {
    return range[index % range.length];
  }
  // `:247-251`.
  final mapping = _schemeMapping(scheme);
  if (mapping != null) {
    return _hex(
      FluentDataVizPalette.resolve(
        mapping[index % mapping.length],
        isDark: isDark,
      ),
    );
  }
  // `:254` passes 0 as the offset, which is also `getNextColor`'s default
  // (`colors.ts:134`).
  return _hex(FluentDataVizPalette.next(index, isDark: isDark));
}

/// The colour for one legend, cached in [colorMap]
/// (`VegaLiteColorAdapter.ts:267-285`).
///
/// The palette index is the map's **size** at the moment of the first lookup
/// (`:280`), so insertion order is the palette order — exactly as on the Plotly
/// side. Callers must not be reordered.
String getVegaColorFromMap(
  String legend,
  Map<String, String> colorMap,
  String? scheme,
  List<String>? range, {
  required bool isDark,
}) {
  // `:275-277`.
  final cached = colorMap[legend];
  if (cached != null) {
    return cached;
  }
  // `:280-283`.
  final colour = getVegaColor(colorMap.length, scheme, range, isDark: isDark);
  colorMap[legend] = colour;
  return colour;
}

/// The sixteen five-stop sequential and diverging ramps
/// (`VegaLiteColorAdapter.ts:291-308`).
///
/// Five stops each, matching the D3 and Vega defaults (`:289`). The last three
/// are diverging, so their middle stop is the neutral one.
const Map<String, List<String>> kVegaSequentialSchemes = <String, List<String>>{
  'blues': <String>['#deebf7', '#9ecae1', '#4292c6', '#2171b5', '#084594'],
  'greens': <String>['#e5f5e0', '#a1d99b', '#41ab5d', '#238b45', '#005a32'],
  'reds': <String>['#fee0d2', '#fc9272', '#ef3b2c', '#cb181d', '#99000d'],
  'oranges': <String>['#feedde', '#fdbe85', '#fd8d3c', '#e6550d', '#a63603'],
  'purples': <String>['#efedf5', '#bcbddc', '#807dba', '#6a51a3', '#4a1486'],
  'greys': <String>['#f0f0f0', '#bdbdbd', '#969696', '#636363', '#252525'],
  'viridis': <String>['#440154', '#3b528b', '#21918c', '#5ec962', '#fde725'],
  'inferno': <String>['#000004', '#57106e', '#bc3754', '#f98c0a', '#fcffa4'],
  'magma': <String>['#000004', '#51127c', '#b73779', '#fc8961', '#fcfdbf'],
  'plasma': <String>['#0d0887', '#7e03a8', '#cc4778', '#f89540', '#f0f921'],
  'greenblue': <String>['#e0f3db', '#a8ddb5', '#4eb3d3', '#2b8cbe', '#08589e'],
  'yellowgreen': <String>[
    '#ffffcc',
    '#c2e699',
    '#78c679',
    '#31a354',
    '#006837',
  ],
  'yellowgreenblue': <String>[
    '#ffffcc',
    '#a1dab4',
    '#41b6c4',
    '#2c7fb8',
    '#253494',
  ],
  'redyellowgreen': <String>[
    '#d73027',
    '#fc8d59',
    '#fee08b',
    '#91cf60',
    '#1a9850',
  ],
  'blueorange': <String>['#2166ac', '#67a9cf', '#f7f7f7', '#f4a582', '#b2182b'],
  'redblue': <String>['#ca0020', '#f4a582', '#f7f7f7', '#92c5de', '#0571b0'],
};

/// Linearly interpolates between two six-digit hex colours
/// (`VegaLiteColorAdapter.ts:349-362`).
///
/// [c1] and [c2] must be `#rrggbb`; anything else throws a [FormatException],
/// where upstream would silently emit the string `#NaNNaNNaN`.
/// `Math.round` per channel is half-up, which is what `D3Rgb.formatHex` does
/// (`d3-color/src/color.js:292-299`) and what Dart's own `round()` — half away
/// from zero — would not, for a [t] outside 0..1.
String interpolateHexColor(String c1, String c2, double t) {
  // 1, 3 and 5 are the red, green and blue offsets past the leading `#`;
  // 2 is the width of one channel (`:350-355`).
  double channel(String hex, int offset) =>
      int.parse(hex.substring(offset, offset + 2), radix: 16).toDouble();
  // `:357-359`.
  double mix(int offset) {
    final a = channel(c1, offset);
    return a + (channel(c2, offset) - a) * t;
  }

  // `:361` formats each channel as two lower-case hex digits.
  return d3.D3Rgb(mix(1), mix(3), mix(5)).formatHex();
}

/// A sequential or diverging ramp of [steps] stops, or null for an unknown
/// scheme (`VegaLiteColorAdapter.ts:318-344`).
///
/// **Always returns a fresh list.** `VegaLiteSchemaAdapter.ts:3477` calls
/// `.reverse()` on the result, which mutates in place in both languages, so
/// handing back the shared constant would corrupt [kVegaSequentialSchemes] for
/// every later chart. `:325`'s `[...ramp]` is that copy, and the interpolated
/// branch below already builds a new list.
List<String>? getSequentialSchemeColors(String scheme, {int steps = 5}) {
  // `:319`.
  final ramp = kVegaSequentialSchemes[scheme.toLowerCase()];
  if (ramp == null) {
    // `:320-322`.
    return null;
  }
  if (steps == ramp.length) {
    // `:324-326`.
    return List<String>.of(ramp);
  }

  // `:329-343`.
  final result = <String>[];
  for (var i = 0; i < steps; i++) {
    // `:331`: a single step samples the MIDDLE of the ramp, not its start.
    final t = steps == 1 ? 0.5 : i / (steps - 1);
    final pos = t * (ramp.length - 1);
    final lo = pos.floor();
    // `:334`. The clamp and the `frac == 0` short-circuit below are each
    // unobservable on their own — `frac != 0` implies `pos < ramp.length - 1`
    // implies `lo + 1 <= ramp.length - 1`, so the clamp never fires while the
    // short-circuit stands, and [interpolateHexColor] at t = 0 returns its
    // first argument, so the short-circuit changes no output while the clamp
    // stands. They are load-bearing as a pair: delete both and `ramp[hi]`
    // range-errors on the last stop. Mutating either alone leaves the tests
    // green, which is a property of upstream's own code and not a gap.
    final hi = math.min(lo + 1, ramp.length - 1);
    final frac = pos - lo;

    if (frac == 0) {
      // `:338`. Landing exactly on a stop returns it verbatim rather than
      // round-tripping it through the interpolator.
      result.add(ramp[lo]);
    } else {
      result.add(interpolateHexColor(ramp[lo], ramp[hi], frac));
    }
  }
  return result;
}
