import 'package:flutter/widgets.dart';

import '../chart_utils.dart' show areArraysEqual;
import '../d3/color.dart' as d3;
import '../d3/interpolate.dart' as d3;
import '../d3/scale_linear.dart' as d3;
import '../data_viz_palette.dart';

/// Which of Plotly's stock colourways a schema declared.
///
/// `PlotlyColorway` at `PlotlyColorAdapter.ts:9`.
enum FluentPlotlyColorwayKind {
  /// Plotly Express's own ten-colour default.
  plotly,

  /// D3 Category10, which Plotly Express exposes as `px.colors.qualitative.D3`.
  d3,

  /// Anything else — schema colours pass through untranslated.
  others,
}

/// How the declarative Plotly adapter chooses colours.
///
/// `ColorwayType` at `PlotlyColorAdapter.ts:13`; the widget defaults to
/// [FluentPlotlyColorway.byDefault] (`DeclarativeChart.tsx:360`).
enum FluentPlotlyColorway {
  /// Honour the schema's own colours where present, mapping Plotly's stock
  /// palette onto Fluent's.
  byDefault,

  /// Ignore schema colours; always use the Fluent palette.
  builtin,

  /// Reserved upstream; behaves as [builtin]
  /// (`PlotlyColorAdapter.ts:177-179`).
  others,
}

/// Plotly Express's default ten-colour sequence (`PlotlyColorAdapter.ts:15-26`).
const List<String> kDefaultPlotlyColorway = <String>[
  '#636efa',
  '#ef553b',
  '#00cc96',
  '#ab63fa',
  '#ffa15a',
  '#19d3f3',
  '#ff6692',
  '#b6e880',
  '#ff97ff',
  '#fecb52',
];

/// D3 Category10 as Plotly Express ships it (`PlotlyColorAdapter.ts:30-41`).
const List<String> kDefaultD3Colorway = <String>[
  '#1f77b4',
  '#ff7f0e',
  '#2ca02c',
  '#d62728',
  '#9467bd',
  '#8c564b',
  '#e377c2',
  '#7f7f7f',
  '#bcbd22',
  '#17becf',
];

/// Plotly slot to Fluent DataViz token (`PlotlyColorAdapter.ts:43-54`).
const List<FluentDataVizToken> kPlotlyFluentColorway = <FluentDataVizToken>[
  FluentDataVizToken.color1,
  FluentDataVizToken.warning,
  FluentDataVizToken.color8,
  FluentDataVizToken.color4,
  FluentDataVizToken.color7,
  FluentDataVizToken.color6,
  FluentDataVizToken.color2,
  FluentDataVizToken.color5,
  FluentDataVizToken.color9,
  FluentDataVizToken.color10,
];

/// D3 Category10 slot to Fluent DataViz token (`PlotlyColorAdapter.ts:58-69`).
const List<FluentDataVizToken> kD3FluentColorway = <FluentDataVizToken>[
  FluentDataVizToken.color26,
  FluentDataVizToken.warning,
  FluentDataVizToken.color5,
  FluentDataVizToken.error,
  FluentDataVizToken.color4,
  FluentDataVizToken.color17,
  FluentDataVizToken.color22,
  FluentDataVizToken.disabled,
  FluentDataVizToken.color10,
  FluentDataVizToken.color3,
];

/// Legend label to resolved colour string, in assignment order.
///
/// Dart's map literal is a `LinkedHashMap`, so iteration and `length` behave
/// exactly like the JavaScript `Map` at `PlotlyColorAdapter.ts:109` that the
/// palette index is read from.
typedef PlotlyColorMap = Map<String, String>;

/// A palette entry as the lower-case `#rrggbb` string this adapter deals in.
///
/// `getColorFromToken` returns a CSS string upstream (`colors.ts:139-146`);
/// [FluentDataVizPalette] returns a Flutter [Color], and every consumer of this
/// file — the transformers, which end at
/// `rgb(c).copy({opacity}).formatHex8()` — needs the string form. 255 scales
/// Flutter's 0–1 channels onto d3's 0–255 bytes; the alpha is dropped because
/// `formatHex` drops it too (`d3-color/src/color.js:276`) and every token is
/// opaque.
String _hex(Color colour) =>
    d3.D3Rgb(colour.r * 255, colour.g * 255, colour.b * 255).formatHex();

/// Classifies a schema colourway (`PlotlyColorAdapter.ts:71-83`).
FluentPlotlyColorwayKind getPlotlyColorwayKind(
  List<String>? colorway, {
  bool isDonut = false,
}) {
  if (colorway == null || colorway.isEmpty) {
    return FluentPlotlyColorwayKind.others;
  }
  final lower = <String>[for (final c in colorway) c.toLowerCase()];
  // `PlotlyColorAdapter.ts:76` compares the lower-cased colourway against
  // `D3_FLUENTVIZ_COLORWAY_MAPPING` — the *token names* — rather than against
  // `DEFAULT_D3_COLORWAY`, so no hex colourway can ever match and the `d3` arm
  // is dead upstream. Ported against the hex table instead, which is what the
  // arm was written to mean and what the donut path at
  // `PlotlyColorAdapter.ts:116-119` needs to be reachable.
  if (isDonut && areArraysEqual(lower, kDefaultD3Colorway)) {
    return FluentPlotlyColorwayKind.d3;
  }
  if (areArraysEqual(lower, kDefaultPlotlyColorway)) {
    return FluentPlotlyColorwayKind.plotly;
  }
  return FluentPlotlyColorwayKind.others;
}

/// Translates a stock Plotly hex to its Fluent equivalent
/// (`PlotlyColorAdapter.ts:85-105`).
///
/// Upstream takes an `isDonut` here that neither call site passes
/// (`PlotlyColorAdapter.ts:154`, `:163`), so it is left off rather than
/// declared dead.
String _tryMapFluentDataViz(
  String hex,
  FluentPlotlyColorwayKind kind, {
  required bool isDark,
}) {
  if (kind != FluentPlotlyColorwayKind.plotly) {
    return hex;
  }
  // `PlotlyColorAdapter.ts:96-99` re-tests `templateColorway === 'plotly'`
  // inside a branch that already proved it, so the donut path can never select
  // the D3 table — and with `isDonut` never passed it is doubly unreachable.
  // Reproduced. // parity: PlotlyColorAdapter.ts:97
  final idx = kDefaultPlotlyColorway.indexOf(hex.toLowerCase());
  if (idx == -1) {
    return hex;
  }
  return _hex(
    FluentDataVizPalette.resolve(kPlotlyFluentColorway[idx], isDark: isDark),
  );
}

/// Assigns or recalls the colour for [legend] (`PlotlyColorAdapter.ts:107-132`).
///
/// The first ten distinct legends take the Fluent mapping by map size; beyond
/// that the qualitative cycle continues. The map is stateful by design and the
/// donut transformer clears it mid-figure (`PlotlySchemaAdapter.ts:1305`).
String plotlyGetColor(
  String legend,
  PlotlyColorMap map,
  FluentPlotlyColorwayKind kind, {
  required bool isDark,
  bool isDonut = false,
}) {
  final cached = map[legend];
  if (cached != null) {
    return cached;
  }
  final table = isDonut && kind != FluentPlotlyColorwayKind.plotly
      ? kD3FluentColorway
      : kPlotlyFluentColorway;
  final next = map.length < table.length
      ? FluentDataVizPalette.resolve(table[map.length], isDark: isDark)
      // `PlotlyColorAdapter.ts:125` passes 0 as the offset, which is also
      // `getNextColor`'s default (`colors.ts:134`).
      : FluentDataVizPalette.next(map.length, isDark: isDark);
  final hex = _hex(next);
  map[legend] = hex;
  return hex;
}

/// Parses and translates the colours a schema declared
/// (`PlotlyColorAdapter.ts:134-167`).
///
/// Returns a `List<String>` for an array input, a `String` for a scalar and
/// null when there is nothing to translate.
Object? getSchemaColors(
  List<String>? colorway,
  Object? colors,
  PlotlyColorMap map, {
  required bool isDark,
  bool isDonut = false,
}) {
  if (colors == null) {
    return null;
  }
  final kind = getPlotlyColorwayKind(colorway, isDonut: isDonut);
  if (colors is List<Object?>) {
    final out = <String>[];
    for (var i = 0; i < colors.length; i++) {
      final text = colors[i]?.toString().trim();
      // `PlotlyColorAdapter.ts:150` calls `getColor` for every element, even
      // the ones that parse — the map assignment is the point, not the return
      // value, so the palette advances per element either way.
      final fallback = plotlyGetColor(
        'Label_$i',
        map,
        kind,
        isDark: isDark,
        isDonut: isDonut,
      );
      if (text == null || text.isEmpty) {
        out.add(fallback);
        continue;
      }
      final parsed = d3.color(text);
      out.add(
        parsed == null
            ? fallback
            : _tryMapFluentDataViz(parsed.formatHex(), kind, isDark: isDark),
      );
    }
    return out;
  }
  if (colors is String) {
    final parsed = d3.color(colors);
    return parsed == null
        ? plotlyGetColor('Label_0', map, kind, isDark: isDark, isDonut: isDonut)
        : _tryMapFluentDataViz(parsed.formatHex(), kind, isDark: isDark);
  }
  // `PlotlyColorAdapter.ts:166` returns the untouched accumulator for anything
  // that is neither an array nor a string.
  return <String>[];
}

/// Gate on [FluentPlotlyColorway] (`PlotlyColorAdapter.ts:169-180`).
Object? extractColor(
  List<String>? colorway,
  FluentPlotlyColorway colorwayType,
  Object? colors,
  PlotlyColorMap map, {
  required bool isDark,
  bool isDonut = false,
}) => colorwayType == FluentPlotlyColorway.byDefault && colors != null
    ? getSchemaColors(colorway, colors, map, isDark: isDark, isDonut: isDonut)
    : null;

/// Picks the colour for one series (`PlotlyColorAdapter.ts:182-201`).
String resolveColor(
  Object? extracted,
  int index,
  String legend,
  PlotlyColorMap map,
  List<String>? colorway, {
  required bool isDark,
  bool isDonut = false,
}) {
  if (extracted is List<String> && extracted.isNotEmpty) {
    return extracted[index % extracted.length];
  }
  if (extracted is String) {
    return extracted;
  }
  return plotlyGetColor(
    legend,
    map,
    getPlotlyColorwayKind(colorway, isDonut: isDonut),
    isDark: isDark,
    isDonut: isDonut,
  );
}

/// Reads the opacity for one datum (`PlotlyColorAdapter.ts:203-209`).
double getOpacity(Map<String, Object?> series, int index) {
  final marker = series['marker'];
  final markerOpacity = marker is Map<String, Object?>
      ? marker['opacity']
      : null;
  // `PlotlyColorAdapter.ts:204` gates on the truthiness of `marker.opacity`, so
  // an empty array and a literal 0 both fall through to `series.opacity`.
  if (markerOpacity is List<Object?> && markerOpacity.isNotEmpty) {
    final value = markerOpacity[index % markerOpacity.length];
    if (value is num) {
      return value.toDouble();
    }
  }
  if (markerOpacity is num && markerOpacity != 0) {
    return markerOpacity.toDouble();
  }
  final seriesOpacity = series['opacity'];
  // 1 is upstream's `?? 1` default (`PlotlyColorAdapter.ts:208`).
  return seriesOpacity is num ? seriesOpacity.toDouble() : 1;
}

/// Bakes [opacity] into an eight-digit hex string.
///
/// Every colour in the Plotly adapter ends as
/// `rgb(c).copy({opacity}).formatHex8()` — see `PlotlySchemaAdapter.ts:1472`,
/// `:1712`, `:2066`, `:2255`, `:2352`. `formatHex8` rounds the alpha byte with
/// JavaScript's half-up `Math.round`, which `internal/d3/js_math.dart` supplies
/// to `D3Rgb.formatHex8` — Dart's own `round()` is half-away-from-zero and
/// would disagree on a negative half. Every one of those call sites writes
/// `… .formatHex8() ?? color`; `formatHex8` always returns a string, so the
/// fallback is dead and there is nothing to return null for here.
String applyOpacityHex8(String colour, double opacity) {
  // `rgbConvert` on an unparseable specifier yields the all-NaN `Rgb`
  // (`d3-color/src/color.js:231`), whose channels clamp to 0 when formatted
  // (`:292-294`) — so upstream emits opaque black rather than throwing, and so
  // does this. The alpha is replaced below either way.
  final parsed =
      d3.rgb(colour) ?? const d3.D3Rgb(double.nan, double.nan, double.nan);
  return parsed.copyWith(opacity: opacity).formatHex8();
}

/// Builds the continuous colour scale a heatmap marker declares
/// (`PlotlyColorAdapter.ts:211-236`).
///
/// Returns [current] unchanged when the trace carries no numeric marker colour
/// array, which is how a per-trace scale survives across traces.
String Function(double)? createColorScale(
  Map<String, Object?>? layout,
  Map<String, Object?> series,
  String Function(double)? current,
) {
  final coloraxis = layout?['coloraxis'];
  final axis = coloraxis is Map<String, Object?> ? coloraxis : null;
  final scale = axis?['colorscale'];
  final marker = series['marker'];
  final markerColor = marker is Map<String, Object?> ? marker['color'] : null;
  if (axis == null ||
      scale is! List<Object?> ||
      scale.isEmpty ||
      markerColor is! List<Object?> ||
      markerColor.isEmpty ||
      markerColor.first is! num) {
    return current;
  }
  final values = <double>[
    for (final v in markerColor) v is num ? v.toDouble() : double.nan,
  ];
  final cmin = axis['cmin'];
  final cmax = axis['cmax'];
  final dMin = cmin is num
      ? cmin.toDouble()
      : values.reduce((a, b) => a < b ? a : b);
  final dMax = cmax is num
      ? cmax.toDouble()
      : values.reduce((a, b) => a > b ? a : b);
  // `PlotlyColorAdapter.ts:230` — the stop positions are 0–1 fractions of the
  // data extent, so the domain is the extent they address. Index 0 of a stop is
  // its position and index 1 its colour (`:230-231`).
  final domain = <double>[
    for (final stop in scale)
      dMin + ((stop! as List<Object?>)[0]! as num).toDouble() * (dMax - dMin),
  ];
  final range = <String>[
    for (final stop in scale) (stop! as List<Object?>)[1]! as String,
  ];
  if (range.length < 2) {
    // `d3-scale`'s bimap reads `range[1]`, so a one-stop colourscale paints
    // that one colour everywhere rather than throwing.
    final only = range.single;
    return (double _) => only;
  }
  // Upstream is `d3ScaleLinear<string>().domain(…).range(scaleColors)`, whose
  // default interpolator resolves to `interpolateRgb` for colour strings
  // (`d3-interpolate/src/value.js:18`). This port's `ScaleLinear` is numeric
  // only, so the scale carries the *stop index* — normalisation, the polylinear
  // bisect and the constant-0.5 degenerate domain all come from it unchanged —
  // and `interpolateRgb` finishes the segment. The two agree stop for stop:
  // within segment i, `interpolateNumber(i, i + 1)(u)` is `i + u`.
  final positions = d3.scaleLinear()
    ..domainOf(domain)
    ..rangeOf(<double>[for (var i = 0; i < range.length; i++) i.toDouble()]);
  // 2 is the number of stops one segment spans, so the last addressable segment
  // starts one stop short of the end; clamping there is what extrapolates
  // beyond the domain, as `d3-scale/src/continuous.js:52` does with its bisect
  // bounds.
  final lastSegment = range.length - 2;
  return (double value) {
    final position = positions.call(value);
    if (position == null || position.isNaN) {
      // A NaN input gives NaN channels, which the formatter clamps to zero
      // (`d3-color/src/color.js:292-294`) — upstream paints black here.
      return d3.interpolateRgb(range.first, range.last)(double.nan);
    }
    final i = position.floor().clamp(0, lastSegment);
    return d3.interpolateRgb(range[i], range[i + 1])(position - i);
  };
}
