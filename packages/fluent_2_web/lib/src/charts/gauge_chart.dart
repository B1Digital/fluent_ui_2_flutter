import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'chrome/chart_title.dart';
import 'gauge_chart_style.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/d3/axis_geometry.dart';
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_arc.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/chart_common.dart';

/// Which of the two gauge layouts upstream's `variant` prop selects.
///
/// Ports `GaugeChartVariant` (`GaugeChart.types.ts:45`), whose two string
/// literals are `'single-segment'` and `'multiple-segments'`.
enum FluentGaugeChartVariant {
  /// `'single-segment'` — one meaningful segment against a filler remainder.
  singleSegment,

  /// `'multiple-segments'` — upstream's default (`GaugeChart.types.ts:144`).
  multipleSegments,
}

/// How the centred chart value reads.
///
/// Ports `GaugeValueFormat` (`GaugeChart.types.ts:40`).
enum FluentGaugeValueFormat {
  /// `'percentage'` — upstream's default (`GaugeChart.types.ts:106`), e.g.
  /// `50%`.
  percentage,

  /// `'fraction'`, e.g. `50/100`.
  fraction,
}

/// One caller-supplied gauge band.
///
/// Ports `GaugeChartSegment` (`GaugeChart.types.ts`), the shape
/// `_processProps` consumes at `GaugeChart.tsx:186-203`.
@immutable
class FluentGaugeChartSegment {
  /// Creates a segment.
  const FluentGaugeChartSegment({
    required this.legend,
    required this.size,
    this.color,
    this.semantics,
  });

  /// The legend entry this band belongs to.
  final String legend;

  /// The band's extent in value units. A negative size is clamped to zero when
  /// the layout is computed (`GaugeChart.tsx:189`).
  final double size;

  /// An explicit fill. When null the band takes the next qualitative colour
  /// (`GaugeChart.tsx:194-197`).
  final Color? color;

  /// The band's accessible naming.
  final FluentChartSemantics? semantics;
}

/// A gauge band after [FluentGaugeLayout.compute] has resolved its colour and
/// its position on the value scale.
///
/// Ports `ExtendedSegment` (`GaugeChart.tsx:102-105`) — the caller's segment
/// widened with the running `start` and `end` totals.
@immutable
class FluentGaugeSegment {
  /// Creates a resolved segment.
  const FluentGaugeSegment({
    required this.legend,
    required this.size,
    required this.colour,
    required this.start,
    required this.end,
    this.semantics,
  });

  /// The legend entry this band belongs to.
  final String legend;

  /// The band's extent in value units, never negative
  /// (`GaugeChart.tsx:189` — `Math.max(segment.size, 0)`).
  final double size;

  /// The band's resolved fill.
  final Color colour;

  /// Where the band begins on the value scale. Offset by the gauge's minimum,
  /// because the running total is seeded with it (`GaugeChart.tsx:185`).
  final double start;

  /// Where the band ends on the value scale (`GaugeChart.tsx:202`).
  final double end;

  /// The band's accessible naming.
  final FluentChartSemantics? semantics;
}

/// The gauge's coupled margin, radius and breakpoint chain.
///
/// The order matters: the margins fix the space left for the arc, the arc's
/// outer radius picks a row of [kFluentGaugeBreakpoints], and that row fixes
/// both the arc width — hence the inner radius — and the chart-value font
/// size. One wrong margin flips a whole tier, turning a 12px band into a 16px
/// one and 20px text into 24px.
@immutable
class FluentGaugeLayout {
  const FluentGaugeLayout._({
    required this.margins,
    required this.outerRadius,
    required this.innerRadius,
    required this.arcWidth,
    required this.chartValueFontSize,
    required this.minValue,
    required this.maxValue,
    required this.needleLength,
    required this.origin,
    required this.segments,
  });

  /// Lays a gauge out inside [size].
  ///
  /// [size] is the chart's LOGICAL box, legend included: upstream's `_height`
  /// is the root element's height and the svg is drawn 32 shorter
  /// (`GaugeChart.tsx:594`), so passing the svg's own height would move the
  /// origin up by a legend.
  ///
  /// Ports `_getMargins` (`GaugeChart.tsx:109-117`), the outer radius at
  /// `:138-141`, `_getStylesBasedOnBreakpoint` (`:167-180`), `_processProps`
  /// (`:184-206`), the needle length at `:253` and the root translate at
  /// `:599`.
  static FluentGaugeLayout compute({
    required Size size,
    required List<FluentGaugeChartSegment> segments,
    required double minValue,
    double? maxValue,
    required bool hasTitle,
    required bool hasSublabel,
    required bool hideMinMax,
    required bool hideLegend,
    required double gaugeMargin,
    required double labelWidth,
    required double labelHeight,
    required double labelOffset,
    required double titleOffset,
    required double extraNeedleLength,
    required double legendsHeight,
    required Color unknownColour,
    required bool isDark,
  }) {
    // GaugeChart.tsx:110-116.
    final horizontal =
        (hideMinMax ? 0.0 : labelOffset + labelWidth) + gaugeMargin;
    final margins = EdgeInsets.fromLTRB(
      horizontal,
      // The no-title term is EXTRA_NEEDLE_LENGTH / 2, which is 2 — just enough
      // for the needle's half stroke to clear the top of the box.
      (hasTitle ? titleOffset + labelHeight : extraNeedleLength / 2) +
          gaugeMargin,
      horizontal,
      (hasSublabel ? labelOffset + labelHeight : 0.0) + gaugeMargin,
    );
    // GaugeChart.tsx:119.
    final legend = hideLegend ? 0.0 : legendsHeight;

    // GaugeChart.tsx:138-141. Only the width term is halved: the gauge is a
    // half disc, so it spans 2R horizontally and R vertically.
    final outerRadius = math.min(
      (size.width - (margins.left + margins.right)) / 2,
      size.height - (margins.top + margins.bottom + legend),
    );

    // GaugeChart.tsx:167-179 — scan from the largest tier down, then fall back
    // to the first entry rather than to nothing. The comparison is `>=`, so a
    // radius exactly at a minRadius belongs to that tier, not the one below.
    var breakpoint = kFluentGaugeBreakpoints.first;
    for (var i = kFluentGaugeBreakpoints.length - 1; i >= 0; i--) {
      if (outerRadius >= kFluentGaugeBreakpoints[i].minRadius) {
        breakpoint = kFluentGaugeBreakpoints[i];
        break;
      }
    }
    // GaugeChart.tsx:143.
    final innerRadius = outerRadius - breakpoint.arcWidth;

    // GaugeChart.tsx:185-206 — total is SEEDED with minValue, which is why
    // start and end are offset by it.
    var total = minValue;
    final processed = <FluentGaugeSegment>[];
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      // GaugeChart.tsx:189 — Math.max(segment.size, 0).
      final segmentSize = math.max(segment.size, 0.0);
      total += segmentSize;
      processed.add(
        FluentGaugeSegment(
          legend: segment.legend,
          size: segmentSize,
          // GaugeChart.tsx:194-197 — getNextColor(index, 0, false). Every
          // imperative chart leaves the isDark flag false upstream; here the
          // theme supplies it.
          colour: segment.color ?? FluentDataVizPalette.next(i, isDark: isDark),
          start: total - segmentSize,
          end: total,
          semantics: segment.semantics,
        ),
      );
    }
    // GaugeChart.tsx:204-213. The comparison is a strict `<`, so a maximum
    // exactly at the running total appends nothing.
    if (maxValue != null && total < maxValue) {
      processed.add(
        FluentGaugeSegment(
          legend: 'Unknown',
          size: maxValue - total,
          colour: unknownColour,
          start: total,
          end: maxValue,
        ),
      );
      total = maxValue;
    }

    return FluentGaugeLayout._(
      margins: margins,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      arcWidth: breakpoint.arcWidth,
      chartValueFontSize: breakpoint.fontSize,
      minValue: minValue,
      // GaugeChart.tsx:240 — the resolved maximum is the running total, seed
      // included.
      maxValue: total,
      // GaugeChart.tsx:253.
      needleLength: outerRadius - innerRadius + extraNeedleLength,
      // GaugeChart.tsx:599 — translate(_width / 2, _height - (margins.bottom +
      // legendsHeight)), against the LOGICAL height rather than the svg's
      // already-shortened one at :594.
      origin: Offset(size.width / 2, size.height - (margins.bottom + legend)),
      segments: List<FluentGaugeSegment>.unmodifiable(processed),
    );
  }

  /// Ports `calcNeedleRotation` (`GaugeChart.tsx:44-52`), in degrees.
  static double needleRotation(
    double chartValue,
    double minValue,
    double maxValue,
  ) {
    // GaugeChart.tsx:45 — the half disc spans 180 degrees.
    final rotation = (chartValue - minValue) / (maxValue - minValue) * 180;
    // GaugeChart.tsx:46-50.
    if (rotation < 0) return 0;
    if (rotation > 180) return 180;
    return rotation;
  }

  /// Space reserved around the arc (`GaugeChart.tsx:110-116`).
  final EdgeInsets margins;

  /// The arc band's outer radius (`GaugeChart.tsx:138-141`).
  final double outerRadius;

  /// The arc band's inner radius (`GaugeChart.tsx:143`).
  final double innerRadius;

  /// The band's radial thickness, from the chosen breakpoint
  /// (`GaugeChart.tsx:169`).
  final double arcWidth;

  /// The centred chart value's font size, from the chosen breakpoint
  /// (`GaugeChart.tsx:172`).
  final double chartValueFontSize;

  /// The gauge's minimum, unchanged from the caller.
  final double minValue;

  /// The gauge's resolved maximum: the running segment total, seeded with
  /// [minValue] and raised by any filler (`GaugeChart.tsx:240`).
  final double maxValue;

  /// The needle's length — the arc width plus the overshoot
  /// (`GaugeChart.tsx:253`).
  final double needleLength;

  /// The gauge's pivot, in chart coordinates (`GaugeChart.tsx:599`).
  final Offset origin;

  /// The resolved bands, with the `Unknown` filler appended when the caller's
  /// maximum exceeds their total (`GaugeChart.tsx:204-213`).
  final List<FluentGaugeSegment> segments;
}

/// One painted arc of a gauge, with the segment it came from.
@immutable
class FluentGaugeArc {
  /// Creates an arc.
  const FluentGaugeArc({
    required this.path,
    required this.segmentIndex,
    required this.startAngle,
    required this.endAngle,
  });

  /// The path, in painter coordinates relative to the gauge origin.
  final Path path;

  /// Index into [FluentGaugeLayout.segments]. Under right-to-left the paint
  /// order reverses but the index does not (`GaugeChart.tsx:233`).
  final int segmentIndex;

  /// Start angle, d3 convention.
  final double startAngle;

  /// End angle, d3 convention.
  final double endAngle;
}

/// Builds the gauge's arcs.
///
/// Unlike the donut, this call sets `padRadius` explicitly to the outer radius
/// (`GaugeChart.tsx:218`), so `p0 = asin(R / r0 * sin(1 / R))` grows sharply as
/// the inner radius shrinks and the two rings are trimmed by visibly different
/// amounts.
List<FluentGaugeArc> fluentGaugeArcs(
  FluentGaugeLayout layout, {
  required double arcPadding,
  required double cornerRadius,
  required bool isRtl,
}) {
  final ordered = isRtl
      // GaugeChart.tsx:219 — the ARRAY is reversed, not the angles.
      ? layout.segments.reversed.toList(growable: false)
      : layout.segments;
  final span = layout.maxValue - layout.minValue;
  final generator = d3.Arc(
    // GaugeChart.tsx:216.
    cornerRadius: cornerRadius,
    // GaugeChart.tsx:218 — the one caller in the port that pins padRadius.
    padRadius: layout.outerRadius,
  );
  // GaugeChart.tsx:220 — nine o'clock in screen terms, because d3's arc
  // subtracts a further quarter turn internally.
  var prevAngle = -math.pi / 2;
  final arcs = <FluentGaugeArc>[];
  for (var index = 0; index < ordered.length; index++) {
    final segment = ordered[index];
    // GaugeChart.tsx:223 — the half disc is PI wide.
    final endAngle =
        prevAngle + (span == 0 ? 0 : segment.size / span) * math.pi;
    final sink = d3.UiPathSink();
    generator(
      d3.ArcDatum(
        startAngle: prevAngle,
        endAngle: endAngle,
        innerRadius: layout.innerRadius,
        outerRadius: layout.outerRadius,
        // GaugeChart.tsx:217 — the pad angle is a constant arc LENGTH of
        // ARC_PADDING px converted to radians at the outer radius.
        padAngle: arcPadding / layout.outerRadius,
      ),
      sink,
    );
    arcs.add(
      FluentGaugeArc(
        path: sink.path,
        segmentIndex: isRtl ? layout.segments.length - 1 - index : index,
        startAngle: prevAngle,
        endAngle: endAngle,
      ),
    );
    prevAngle = endAngle;
  }
  return arcs;
}

/// The needle outline, already translated into the frame the rotation spins.
///
/// `GaugeChart.tsx:255-269` authors the path around a local origin and then
/// translates it by `-innerRadius + EXTRA_NEEDLE_LENGTH / 2` **inside** the
/// `rotate(theta, 0, 0)` group, so the pivot stays at the gauge origin and the
/// hub ends up on the far side of it, riding the arc band. Both arc commands
/// use sweep flag 0 — the anticlockwise sweep — with radii
/// `halfStrokeWidth + 1` and `halfStrokeWidth + 3`, which is 2 and 4 at the
/// fixed stroke width of 2. Both caps therefore bulge OUTWARD, which is what
/// the captured bbox of `[-18, -4, 22, 8]` in
/// `charts-gaugechart--gauge-chart-basic` records for a 16px needle.
Path fluentGaugeNeedlePath({
  required double innerRadius,
  required double needleLength,
  required double extraNeedleLength,
  required double strokeWidth,
}) {
  final half = strokeWidth / 2;
  // GaugeChart.tsx:260-261 — halfStrokeWidth + 1.
  final tipRadius = half + 1;
  // GaugeChart.tsx:259,262-263 — halfStrokeWidth + 3.
  final hubRadius = half + 3;
  // GaugeChart.tsx:268.
  final dx = -innerRadius + extraNeedleLength / 2;
  return (Path()
        ..moveTo(0, -hubRadius)
        ..lineTo(-needleLength, -tipRadius)
        ..arcToPoint(
          Offset(-needleLength, tipRadius),
          radius: Radius.circular(tipRadius),
          // Sweep flag 0 in SVG is the anticlockwise sweep, which is
          // `clockwise: false` here.
          clockwise: false,
        )
        ..lineTo(0, hubRadius)
        ..arcToPoint(
          Offset(0, -hubRadius),
          radius: Radius.circular(hubRadius),
          clockwise: false,
        )
        ..close())
      .shift(Offset(dx, 0));
}

/// Paints a gauge: the limits, then the bands, then the needle, then the
/// centred value and its sublabel.
///
/// The order is upstream's document order (`GaugeChart.tsx:610-698`) and SVG
/// paints in document order, so the needle covers the band it points at and the
/// chart value sits over both. The chart title is NOT painted here: upstream
/// delegates it to `ChartTitle` (`:601`), which the port renders as a widget so
/// its tooltip stays interactive.
class FluentGaugeChartPainter extends CustomPainter {
  /// Creates a painter over pre-resolved geometry.
  const FluentGaugeChartPainter({
    required this.layout,
    required this.arcs,
    required this.colours,
    required this.opacities,
    required this.focusedIndex,
    required this.needlePath,
    required this.needleRotationDegrees,
    required this.needleFill,
    required this.needleStroke,
    required this.needleStrokeWidth,
    required this.segmentFocusStrokeColour,
    required this.focusStrokeWidth,
    required this.minLabel,
    required this.maxLabel,
    required this.valueLabel,
    required this.sublabel,
    required this.labelOffset,
    required this.limitsTextStyle,
    required this.chartValueTextStyle,
    required this.sublabelTextStyle,
    required this.measurer,
    required this.textDirection,
  });

  /// The resolved margins, radii and origin.
  final FluentGaugeLayout layout;

  /// The bands to paint, in paint order.
  final List<FluentGaugeArc> arcs;

  /// Fill per [FluentGaugeLayout.segments] entry, indexed by
  /// [FluentGaugeArc.segmentIndex].
  ///
  /// Already flattened for high contrast by the widget: see
  /// `FluentChartColors.flattenMark`. Upstream's marks carry no
  /// `forced-color-adjust`, so a palette colour that reached the canvas in
  /// forced-colours mode would draw an invisible gauge.
  final List<Color> colours;

  /// Opacity per segment — 1, or the dimmed value when another legend is
  /// highlighted (`GaugeChart.tsx:641`).
  final List<double> opacities;

  /// The segment index that owns keyboard focus, or null.
  final int? focusedIndex;

  /// The needle outline from [fluentGaugeNeedlePath].
  final Path needlePath;

  /// The needle's rotation about [FluentGaugeLayout.origin], in degrees.
  final double needleRotationDegrees;

  /// The needle's fill (`useGaugeChartStyles.styles.ts` — `.needle`).
  final Color needleFill;

  /// The needle's outline colour.
  final Color needleStroke;

  /// The needle's outline width (`GaugeChart.tsx:257`).
  final double needleStrokeWidth;

  /// The ring drawn around a focused band. `GaugeChart.tsx:639` toggles only
  /// the WIDTH, so the colour comes from the segment class either way.
  final Color segmentFocusStrokeColour;

  /// The focus ring's width, which upstream reuses `ARC_PADDING` for
  /// (`GaugeChart.tsx:639`).
  final double focusStrokeWidth;

  /// The formatted minimum, or null when `hideMinMax` is set.
  final String? minLabel;

  /// The formatted maximum, or null when `hideMinMax` is set.
  final String? maxLabel;

  /// The centred value, already truncated to the hole.
  final String valueLabel;

  /// The optional line under the value, already truncated.
  final String? sublabel;

  /// The gap between the arc's outer edge and the limit labels
  /// (`GaugeChart.tsx:613`).
  final double labelOffset;

  /// Text style for the two limit labels.
  final TextStyle limitsTextStyle;

  /// Text style for the centred value, its size already taken from the
  /// breakpoint (`GaugeChart.tsx:679`).
  final TextStyle chartValueTextStyle;

  /// Text style for the sublabel.
  final TextStyle sublabelTextStyle;

  /// The chart's one measurer.
  final FluentChartTextMeasurer measurer;

  /// Reading direction — the limits swap sides under right-to-left
  /// (`GaugeChart.tsx:613`, `:623`).
  final TextDirection textDirection;

  /// Draws [text] with its SVG anchor and dominant baseline honoured.
  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at,
    FluentAxisTextAnchor anchor,
    FluentChartTitleBaseline baseline,
  ) {
    if (text.isEmpty) {
      return;
    }
    final metrics = measurer.measure(text, style);
    final painter = measurer.layoutPainter(text, style);
    final dx = switch (anchor) {
      FluentAxisTextAnchor.start => 0.0,
      FluentAxisTextAnchor.middle => -metrics.width / 2,
      FluentAxisTextAnchor.end => -metrics.width,
    };
    // The baseline offset positions the named baseline; TextPainter paints from
    // the top-left, so the ascent comes back off.
    final dy = fluentChartBaselineOffset(baseline, metrics) - metrics.ascent;
    painter.paint(canvas, at + Offset(dx, dy));
    painter.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // GaugeChart.tsx:599 — every child below is placed against the origin.
    canvas.translate(layout.origin.dx, layout.origin.dy);

    final isRtl = textDirection == TextDirection.rtl;
    // GaugeChart.tsx:613 — (_isRTL ? 1 : -1) * (_outerRadius + LABEL_OFFSET),
    // with text-anchor "end", which under direction: rtl anchors the LEFT edge.
    final limitX = layout.outerRadius + labelOffset;
    if (minLabel != null) {
      _text(
        canvas,
        minLabel!,
        limitsTextStyle,
        Offset(isRtl ? limitX : -limitX, 0),
        isRtl ? FluentAxisTextAnchor.start : FluentAxisTextAnchor.end,
        FluentChartTitleBaseline.alphabetic,
      );
    }
    if (maxLabel != null) {
      _text(
        canvas,
        maxLabel!,
        limitsTextStyle,
        Offset(isRtl ? -limitX : limitX, 0),
        isRtl ? FluentAxisTextAnchor.end : FluentAxisTextAnchor.start,
        FluentChartTitleBaseline.alphabetic,
      );
    }

    for (final arc in arcs) {
      // GaugeChart.tsx:641 — the element `opacity` covers fill and stroke
      // alike, so it multiplies both paints below.
      final opacity = opacities[arc.segmentIndex];
      canvas.drawPath(
        arc.path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = colours[arc.segmentIndex].withValues(
            alpha: colours[arc.segmentIndex].a * opacity,
          ),
      );
      if (focusedIndex == arc.segmentIndex) {
        // GaugeChart.tsx:639 — the focus indicator is a widening of the
        // segment's own stroke, never a recolouring.
        canvas.drawPath(
          arc.path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = focusStrokeWidth
            ..color = segmentFocusStrokeColour.withValues(
              alpha: segmentFocusStrokeColour.a * opacity,
            ),
        );
      }
    }

    canvas.save();
    // GaugeChart.tsx:265 — rotate(theta, 0, 0). The path already carries the
    // translate that sits INSIDE this group, so the pivot is the origin.
    canvas.rotate(needleRotationDegrees * math.pi / 180);
    canvas.drawPath(
      needlePath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = needleFill,
    );
    canvas.drawPath(
      needlePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = needleStrokeWidth
        ..color = needleStroke,
    );
    canvas.restore();

    // GaugeChart.tsx:673-683 — x=0, y=0, text-anchor middle, the default
    // alphabetic baseline.
    _text(
      canvas,
      valueLabel,
      chartValueTextStyle,
      Offset.zero,
      FluentAxisTextAnchor.middle,
      FluentChartTitleBaseline.alphabetic,
    );
    if (sublabel != null) {
      // GaugeChart.tsx:688-694 — x=0, y=4, dominant-baseline hanging.
      _text(
        canvas,
        sublabel!,
        sublabelTextStyle,
        Offset(0, labelOffset),
        FluentAxisTextAnchor.middle,
        FluentChartTitleBaseline.hanging,
      );
    }

    canvas.restore();
  }

  // ponytail: the widget rebuilds `arcs` and both colour lists on every build,
  // so no field-by-field comparison here could ever return false — `Path` and
  // `FluentGaugeArc` have no value equality. Give them one if a profile ever
  // shows the gauge repainting hot.
  @override
  bool shouldRepaint(FluentGaugeChartPainter oldDelegate) => true;
}
