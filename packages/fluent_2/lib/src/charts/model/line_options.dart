import 'package:flutter/widgets.dart';

/// The interpolation a line is drawn with.
///
/// Ports the five string arms of `LineChartLineOptions.curve`
/// (`types/DataPoint.ts:448`). The sixth arm is a caller-supplied
/// `CurveFactory`; a chart passes that straight to `getCurveFactory`, so it has
/// no member here.
enum FluentLineCurve {
  /// `'linear'` — straight segments.
  linear,

  /// `'natural'` — a natural cubic spline.
  natural,

  /// `'step'` — a step whose riser sits midway between points.
  step,

  /// `'stepAfter'` — a step that holds the value until the next x.
  stepAfter,

  /// `'stepBefore'` — a step that jumps to the value at the previous x.
  stepBefore,
}

/// Which parts of a series are drawn.
///
/// Ports `LineChartLineOptions.mode` (`types/DataPoint.ts:453-471`), an
/// eighteen-literal union. It is a flag set here and not an enum because
/// upstream only ever tests it with `String.includes` — every consumer asks
/// "does this mode contain markers" or "does it contain text", never "is it
/// exactly `'lines+markers+text'`".
@immutable
class FluentLineMode {
  /// Creates a mode from its three flags.
  const FluentLineMode({
    this.lines = true,
    this.markers = false,
    this.text = false,
    this.upstreamName = 'lines',
  });

  /// Reads the three flags out of an upstream mode literal.
  ///
  /// Substring tests, exactly as upstream does them, so `'text+markers'` and
  /// `'markers+text'` are the same thing and `'none'` is all three off. The
  /// gauge modes (`'gauge'`, `'number'`, `'delta'` and their combinations,
  /// `types/DataPoint.ts:462-468`) contain none of the three substrings and so
  /// report every flag false; GaugeChart reads [upstreamName] instead.
  static FluentLineMode parse(String upstream) => FluentLineMode(
    lines: upstream.contains('lines'),
    markers: upstream.contains('markers'),
    text: upstream.contains('text'),
    upstreamName: upstream,
  );

  /// Whether the connecting line is drawn.
  final bool lines;

  /// Whether a marker is drawn at each point.
  final bool markers;

  /// Whether each point's `text` label is drawn.
  final bool text;

  /// The literal this mode was parsed from, kept because GaugeChart switches on
  /// the whole string rather than on the three flags.
  final String upstreamName;
}

/// How one line is stroked.
///
/// Ports `LineChartLineOptions` (`types/DataPoint.ts:407-472`). That interface
/// declares eight properties and extends `SVGProps<SVGPathElement>`, which is
/// where the ninth, [fill], comes from. `fill` is kept because it is a rendering
/// feature and not a pass-through attribute: `LineChart.tsx:1316` reads it and
/// `:1318-1343` closes the path and paints an area from it (spec §5.6).
///
/// The four polar-only members that also arrive through the `SVGProps` door —
/// `direction`, `axisLabel`, `rotation` and `originXOffset`
/// (`scatterpolar-utils.tsx:79-85`) — are **not** here; they live on
/// `FluentPolarLineOptions`, because they say nothing about a stroke.
@immutable
class FluentLineOptions {
  /// Creates a line configuration. Every field is optional.
  const FluentLineOptions({
    this.strokeWidth,
    this.strokeDasharray,
    this.strokeDashoffset,
    this.strokeLinecap,
    this.lineBorderWidth,
    this.lineBorderColor,
    this.curve,
    this.mode,
    this.fill,
  });

  /// Stroke width in logical pixels, overriding the chart-level width.
  ///
  /// No default here: LineChart falls back to 4, PolarChart and
  /// GroupedVerticalBarChart to 3, so the default belongs to the consumer.
  final double? strokeWidth;

  /// The SVG `stroke-dasharray` string, parsed into a dash list at paint time.
  final String? strokeDasharray;

  /// The SVG `stroke-dashoffset`.
  final double? strokeDashoffset;

  /// The cap drawn at each end of a subpath. `'inherit'` maps to null.
  final StrokeCap? strokeLinecap;

  /// Width of the halo stroked behind the line. Null means no halo.
  final double? lineBorderWidth;

  /// Colour of that halo.
  ///
  /// `types/DataPoint.ts:439` documents it as white; every runtime call site
  /// passes `colorNeutralBackground1`, so a null here resolves against the theme
  /// rather than against the doc comment.
  final Color? lineBorderColor;

  /// The interpolation. Null falls back to the consumer's own default.
  final FluentLineCurve? curve;

  /// Which parts of the series are drawn.
  final FluentLineMode? mode;

  /// `'toself'` closes the path and fills it — the scatterpolar area
  /// (`LineChart.tsx:1316-1343`). Any other value is inert.
  final String? fill;
}
