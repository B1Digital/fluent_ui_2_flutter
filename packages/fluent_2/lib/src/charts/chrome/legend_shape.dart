import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The shape a legend swatch and a popover swatch are drawn with.
///
/// Ports `LegendShape` (`Legends.types.ts:269`), which is the union of the
/// literals `'default'` and `'triangle'` with the keys of `Points`
/// (`utilities.ts:1713-1721`) and `CustomPoints` (`:1724-1726`). `'triangle'`
/// appears on both sides of that union, so the ten Dart values below are the
/// complete set.
///
/// The painter, the path builder and the stripe painter for these shapes are
/// added to this file at stage 6; the enum lives here from stage 3 because four
/// `model/` files carry a `legendShape` field.
enum FluentChartLegendShape {
  /// `'default'` — the filled rectangle every chart falls back to.
  defaultShape(null),

  /// `'triangle'` — the standalone literal at `Legends.types.ts:269`, distinct
  /// from `Points.triangle` only in that a chart may name it without the
  /// `Points` table being consulted.
  triangle(2),

  /// `Points.circle` (`utilities.ts:1714`).
  circle(0),

  /// `Points.square` (`utilities.ts:1715`).
  square(1),

  /// `Points.diamond` (`utilities.ts:1717`).
  diamond(3),

  /// `Points.pyramid` (`utilities.ts:1718`).
  pyramid(4),

  /// `Points.hexagon` (`utilities.ts:1719`).
  hexagon(5),

  /// `Points.pentagon` (`utilities.ts:1720`).
  pentagon(6),

  /// `Points.octagon` (`utilities.ts:1721`).
  octagon(7),

  /// `CustomPoints.dottedLine` (`utilities.ts:1725`).
  dottedLine(null);

  const FluentChartLegendShape(this.pointIndex);

  /// This shape's ordinal in upstream's `Points` enum, or null when it is not a
  /// member of it.
  ///
  /// `ChartPopover.tsx:216` selects a swatch with `Points[index % 8]`, so the
  /// ordinals are load-bearing and cannot be renumbered.
  final int? pointIndex;
}

/// Half of the SVG viewport that the nine legend shapes are drawn into.
///
/// `shape.tsx:41` sets `viewBox="-1 -1 14 14"`, so user-space (0, 0) sits one
/// pixel in from the top-left of the rendered box. The offset exists to make
/// room for the 2px centred stroke `Legends.tsx:365` puts on every path.
///
/// Verified against Oracle B: every `fui-legend__shape` swatch in the corpus
/// reports `getCTM()` as `[1, 0, 0, 1, 1, 1]`, that trailing `1, 1` being this
/// translation.
const double kLegendShapeViewBoxOrigin = 1;

/// Edge length of the rendered legend shape viewport, in logical pixels.
///
/// `shape.tsx:39-40` and `:46-49` both pin the `<svg>` to 14×14 — once as an
/// attribute and once as an inline style — so the shape occupies 14 pixels even
/// though its filled area is 12.
///
/// Verified against Oracle B: the twelve unrotated swatches in the corpus
/// measure 14×14. The two diamonds measure 19.799, which is 14 × √2, because
/// `shape.tsx:43-45` rotates the whole element and CSS reports the rotated box.
const double kLegendShapeViewportSize = 14;

// `kPointWidthRatios` was declared here, a `FluentChartLegendShape`-keyed
// transcription of `pointTypes[*].widthRatio` (`utilities.ts:1747-1771`), and
// nothing read it. It is deleted rather than wired, because the table already
// has a port and that port is already applied where upstream applies it.
//
// `grep -rn widthRatio` over `crawlers/fluentui-react-charts/out/charts/src`
// returns the table (`utilities.ts:1738`, `:1749-1770`), one use
// (`LineChart.tsx:493-494`) and an unrelated local in `funnelGeometry.ts:187`.
// The one use sits in `_getPath` and narrows the box handed to `_getPointPath`
// (`LineChart.tsx:82-137`), the LineChart *data-point marker* builder, whose
// hexagon reaches x ± w and octagon x ± 1.207w. That is
// `FluentLineMarkerPainter.kWidthRatios` in `line_chart.dart`, which
// `FluentLineChartDelegate.markersFor` divides by at the `:494` position.
//
// The legend swatch never meets a ratio: `shape.tsx:32-54` is a single
// ratio-free code path that renders whichever of the nine authored `d` strings
// (`:19-30`) the shape names, and `ChartPopover.tsx:211-217` renders that same
// component. So a hexagon swatch spans the authored 0..12 exactly as a triangle
// does, which is what [fluentChartLegendShapePath] returns and what Oracle B's
// fourteen `fui-legend__shape` captures measure.

/// The marker outline for [shape], in the authored 0..12 user space of
/// `shape.tsx:19-30`.
///
/// The returned path is **not** shifted by [kLegendShapeViewBoxOrigin] and is
/// not rotated; `FluentChartLegendShapePainter` applies both, because the
/// rotation upstream is on the `<svg>` element rather than the `<path>` and so
/// happens outside the viewBox mapping.
///
/// [FluentChartLegendShape.defaultShape] returns an empty path: `shape.tsx:34`
/// tests membership of the nine-key table and renders a plain bordered `div`
/// instead when the lookup misses.
Path fluentChartLegendShapePath(FluentChartLegendShape shape) {
  switch (shape) {
    case FluentChartLegendShape.circle:
      // shape.tsx:20 — `M1 6 A5 5 0 1 0  12 6 M1 6 A5 5 0 0 1  12 6`. Two
      // half-arcs of radius 5 between (1, 6) and (12, 6), one large-arc sweep 0
      // and one small-arc sweep 1. The chord is 11 and the radius 5, so the
      // arcs are over-constrained and SVG scales the radii up by 11 / 10; the
      // result is the circle on that chord as its diameter. Oracle B's
      // charts-scatterchart--scatter-chart-log-axis-example measures the box as
      // (1, 0.5, 12, 11.5), which is that 5.5 radius about (6.5, 6).
      return Path()
        ..moveTo(1, 6)
        ..arcToPoint(
          const Offset(12, 6),
          radius: const Radius.circular(5),
          largeArc: true,
        )
        ..moveTo(1, 6)
        ..arcToPoint(
          const Offset(12, 6),
          radius: const Radius.circular(5),
          clockwise: false,
        );
    case FluentChartLegendShape.square:
      // shape.tsx:21 — `M1 1 L12 1 L12 12  L1 12 L1 1 Z`.
      return Path()
        ..moveTo(1, 1)
        ..lineTo(12, 1)
        ..lineTo(12, 12)
        ..lineTo(1, 12)
        ..close();
    case FluentChartLegendShape.triangle:
    case FluentChartLegendShape.pyramid:
      // shape.tsx:22-23 — `M6 10L8.74228e-07 -1.04907e-06L12 0L6 10Z`. The two
      // exponent literals are float noise for zero and are written out verbatim
      // so a reader diffing against the TypeScript sees the same numbers.
      return Path()
        ..moveTo(6, 10)
        ..lineTo(8.74228e-07, -1.04907e-06)
        ..lineTo(12, 0)
        ..close();
    case FluentChartLegendShape.diamond:
      // shape.tsx:24 — `M2 2 L10 2 L10 10  L2 10 L2 2 Z`, a square that only
      // becomes a diamond under the 45 degree rotation applied at :43-45.
      return Path()
        ..moveTo(2, 2)
        ..lineTo(10, 2)
        ..lineTo(10, 10)
        ..lineTo(2, 10)
        ..close();
    case FluentChartLegendShape.hexagon:
      // shape.tsx:25 — `M9 0H3L0 5L3 10H9L12 5L9 0Z`.
      return Path()
        ..moveTo(9, 0)
        ..lineTo(3, 0)
        ..lineTo(0, 5)
        ..lineTo(3, 10)
        ..lineTo(9, 10)
        ..lineTo(12, 5)
        ..close();
    case FluentChartLegendShape.pentagon:
      // shape.tsx:26 —
      // `M6.06061 0L0 4.21277L2.30303 11H9.69697L12 4.21277L6.06061 0Z`.
      return Path()
        ..moveTo(6.06061, 0)
        ..lineTo(0, 4.21277)
        ..lineTo(2.30303, 11)
        ..lineTo(9.69697, 11)
        ..lineTo(12, 4.21277)
        ..close();
    case FluentChartLegendShape.octagon:
      // shape.tsx:27-28 —
      // `M7.08333 0H2.91667L0 2.91667V7.08333L2.91667 10H7.08333L10 7.08333V2.91667L7.08333 0Z`.
      return Path()
        ..moveTo(7.08333, 0)
        ..lineTo(2.91667, 0)
        ..lineTo(0, 2.91667)
        ..lineTo(0, 7.08333)
        ..lineTo(2.91667, 10)
        ..lineTo(7.08333, 10)
        ..lineTo(10, 7.08333)
        ..lineTo(10, 2.91667)
        ..close();
    case FluentChartLegendShape.dottedLine:
      // shape.tsx:29 — `M0 6 H3 M5 6 H8 M10 6 H13`. Three open subpaths, so it
      // renders only when stroked; the legend strokes every shape at 2px
      // (`Legends.tsx:365`), which is what makes the dashes visible.
      return Path()
        ..moveTo(0, 6)
        ..lineTo(3, 6)
        ..moveTo(5, 6)
        ..lineTo(8, 6)
        ..moveTo(10, 6)
        ..lineTo(13, 6);
    case FluentChartLegendShape.defaultShape:
      return Path();
  }
}

/// Clockwise rotation applied to the whole 14×14 viewport for [shape].
///
/// `shape.tsx:43-45` puts `transform="rotate(θ, 0, 0)"` on the `<svg>` element,
/// not on the `<path>`, with θ = 45 for a diamond, 180 for a pyramid and 0
/// otherwise. The `0, 0` is relative to the element's `transform-origin`, which
/// for an outermost `<svg>` in HTML flow is the CSS initial `50% 50%` — so the
/// spin is about the box centre and neither shape moves off its box.
/// `FluentChartLegendShapePainter` applies it there.
double fluentChartLegendShapeRotation(FluentChartLegendShape shape) =>
    switch (shape) {
      // shape.tsx:44 — 45 degrees.
      FluentChartLegendShape.diamond => math.pi / 4,
      // shape.tsx:44 — 180 degrees.
      FluentChartLegendShape.pyramid => math.pi,
      _ => 0,
    };

/// Paints one legend marker into the box it is given, mapping the
/// [kLegendShapeViewportSize] viewport onto it.
///
/// Reproduces `shape.tsx:32-54` exactly, in its own order: the `transform` on
/// the `<svg>` element runs first, then the viewBox maps user space into the
/// rendered box, then the path is filled and stroked.
///
/// `Legends.tsx:363-366` supplies `fill` (the possibly-dimmed colour),
/// `stroke: legend.color` (never dimmed) and `strokeWidth: 2`. Keeping the
/// stroke at the undimmed colour is what leaves a coloured outline behind when
/// a legend is filtered out, and it is the only visual difference between a
/// dimmed swatch and an absent one.
///
/// The rotation is about the box centre. `shape.tsx:43-45` sets the SVG
/// `transform` attribute on an outermost `<svg>` in HTML flow, which Chromium
/// maps onto the CSS `transform` property and so rotates about
/// `transform-origin: 50% 50%`. Measured in Chrome: a diamond and a pyramid
/// swatch each ink the same 14 columns as an unrotated one, the diamond
/// centred on the box and the pyramid an upward-pointing triangle. The
/// `charts-legends--legends-basic` capture agrees: a diamond turned about the
/// box corner put its centroid (-7.22, +2.93) from the capture's, where turning
/// the centre (7, 7) about the corner predicts (-7, +2.9).
class FluentChartLegendShapePainter extends CustomPainter {
  /// Creates a painter for one marker.
  const FluentChartLegendShapePainter({
    required this.shape,
    required this.fill,
    required this.stroke,
    // Legends.tsx:365 — `strokeWidth: 2` on every legend swatch. The popover's
    // swatch omits it entirely (ChartPopover.tsx:215), which is why this is a
    // parameter rather than a constant.
    this.strokeWidth = 2,
  });

  /// Which of the nine markers to draw.
  final FluentChartLegendShape shape;

  /// Path fill. Already dimmed by the caller when the legend is filtered out.
  final Color fill;

  /// Path stroke. Always `legend.color`, never dimmed (`Legends.tsx:366`).
  final Color stroke;

  /// Stroke width. Zero suppresses the outline.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = fluentChartLegendShapePath(shape);
    if (path.computeMetrics().isEmpty) return;

    canvas.save();
    // The element transform, about the rendered box's centre
    // (`transform-origin: 50% 50%`; see the class docs).
    final centre = size.center(Offset.zero);
    canvas
      ..translate(centre.dx, centre.dy)
      ..rotate(fluentChartLegendShapeRotation(shape))
      ..translate(-centre.dx, -centre.dy);
    // The viewBox mapping (`shape.tsx:39-41`): a viewBox
    // [kLegendShapeViewportSize] units wide is scaled onto the rendered box and
    // its origin then shifted by [kLegendShapeViewBoxOrigin]. Upstream sizes
    // that box itself, so the quotient is always 1 there; the port takes it
    // from the legend style (`legend.dart:416`) and from the popover
    // (`chart_popover.dart:373-374`) instead, and computing the quotient is
    // what stops the two from drifting into a 14-unit marker adrift in a box
    // of some other size.
    //
    // The width alone, because the svg attribute and the viewBox are both
    // square (`shape.tsx:39-41`), so upstream's two scales are equal by
    // construction. The legend keeps the box square even for a line-in-bar
    // legend: `Legends.tsx:376`'s 4px height reaches only the non-svg div
    // (`shape.tsx:35`).
    canvas.scale(size.width / kLegendShapeViewportSize);
    canvas.translate(kLegendShapeViewBoxOrigin, kLegendShapeViewBoxOrigin);

    // dottedLine is three open subpaths and has no interior, so filling it is a
    // no-op rather than a special case.
    canvas.drawPath(path, Paint()..color = fill);
    if (strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FluentChartLegendShapePainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Repeat period of the legend stripe pattern, in logical pixels.
///
/// The final stop of `Legends.tsx:300`'s `repeating-linear-gradient`.
const double kStripePeriod = 4;

/// Where the coloured band begins inside one [kStripePeriod].
///
/// `Legends.tsx:300` is
/// `repeating-linear-gradient(135deg, transparent, transparent 3px, COLOR 1px,
/// COLOR 4px)`. The `1px` is **behind** the `3px` before it. CSS Images 3
/// section 3.4.3 requires each stop to be raised to the largest preceding
/// stop, so `COLOR 1px` becomes `COLOR 3px` and the real rendering is
/// transparent from 0 to 3 and coloured from 3 to 4. The upstream declaration
/// is malformed; its rendering is nonetheless well defined, and this is it.
///
/// Handing those literals to a Dart [LinearGradient] does something else
/// entirely — `stops` must be non-decreasing and normalised, so the values
/// either trip an assertion or are silently reinterpreted. Hence a painter.
const double kStripeColourStart = 3;

/// Distance of [point] along the 135° gradient axis, in logical pixels.
///
/// CSS measures gradient angles clockwise from "up", so 135° points down and
/// right: the unit vector is `(sin 135°, −cos 135°)` = `(√½, √½)` in screen
/// coordinates, where y grows downwards. For a square box at 135° the gradient
/// line's zero crosses the top-left corner, so the box origin is phase zero.
double fluentChartStripePhase(Offset point) =>
    (point.dx + point.dy) / math.sqrt2;

/// Paints the legend's diagonal stripe pattern.
///
/// Used when `Legend.stripePattern` is set, which suppresses the flat
/// background fill (`Legends.tsx:297`, `:377`) and substitutes this. The
/// gradient is the swatch div's `content` (`Legends.tsx:379-381`), which
/// Chromium draws in the div's *content* box, inside its 1px border — so the
/// legend hands this painter that box and phase zero is its top-left corner.
///
/// Antialiasing is off deliberately: the CSS stop at 3px is a hard edge
/// because the preceding stop was clamped onto it, so there is no gradient to
/// smooth, and a smoothed edge would leak colour into the transparent band.
class FluentChartStripePainter extends CustomPainter {
  /// Creates a stripe painter in [color].
  const FluentChartStripePainter({required this.color});

  /// The stripe colour. Already dimmed by the caller when appropriate — the
  /// gradient interpolates `${color}` twice (`Legends.tsx:300`), so it is flat.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // A raster with antialiasing off keeps a pixel when its *centre* falls
    // inside the band, and a centre is also where Chromium evaluates a CSS
    // gradient: the pixel at (x, y) is coloured iff
    // `fluentChartStripePhase(Offset(x + 0.5, y + 0.5))` lands in a coloured
    // band. Measured in Chrome on the 12×12 content box `Legends.tsx:379-381`
    // lays the gradient in: coloured exactly where x + y is 4, 9, 10, 15 or 21.
    // So no half-pixel shift here — an earlier one sampled at pixel corners
    // and put every stripe a diagonal step off.
    //
    // Rotating by +45 degrees makes the gradient axis the canvas x axis, so one
    // band is a rectangle rather than a sheared quadrilateral — and it makes a
    // band's local x its own phase, because the local point (u, 0) is the
    // global (u/√2, u/√2), whose [fluentChartStripePhase] is u.
    canvas.rotate(math.pi / 4);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    // Both bounds come from [fluentChartStripePhase] on the box's own corners,
    // which is the whole of why the shared definition and the painted result
    // cannot drift: the pattern starts at the near corner's phase and the last
    // band drawn is the one the far corner reaches.
    //
    // A loop anchored on anything else moves every band. The previous bound ran
    // from `-(width + height)` in steps of [kStripePeriod], so the bands landed
    // at phases congruent to `-(width + height)` and were correct only when
    // that sum was a multiple of 4 — not for the 12×4 content box of a
    // line-in-bar swatch.
    final nearPhase = fluentChartStripePhase(Offset.zero);
    final farPhase = fluentChartStripePhase(Offset(size.width, size.height));
    for (var phase = nearPhase; phase <= farPhase; phase += kStripePeriod) {
      canvas.drawRect(
        Rect.fromLTWH(
          phase + kStripeColourStart,
          // Perpendicular to the gradient the box spans local y from
          // `-width / √2` to `height / √2`, and [farPhase] is
          // `(width + height) / √2`, so it bounds both.
          -farPhase,
          kStripePeriod - kStripeColourStart,
          2 * farPhase,
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FluentChartStripePainter oldDelegate) =>
      oldDelegate.color != color;
}
