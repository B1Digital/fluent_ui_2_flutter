import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'axis/tick_format.dart';
import 'chrome/chart_popover.dart';
import 'chrome/chart_title.dart';
import 'chrome/legend.dart';
import 'gauge_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/axis_geometry.dart';
import 'internal/d3/js_math.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_arc.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/callout_data.dart';
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
    required this.size,
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
    // `GaugeChart.tsx:206`'s literal 'Unknown'. Localized by the caller —
    // `compute` is static and sees no BuildContext.
    String unknownLegend = 'Unknown',
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
          legend: unknownLegend,
          size: maxValue - total,
          colour: unknownColour,
          start: total,
          end: maxValue,
        ),
      );
      total = maxValue;
    }

    return FluentGaugeLayout._(
      size: size,
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

  /// The box this layout was solved for — upstream's `_width` by `_height`.
  ///
  /// Every coordinate below, [origin] included, is relative to its top-left
  /// corner, so whoever paints the layout has to give the painter a box of
  /// exactly this width or the whole gauge slides sideways. It is carried here
  /// rather than recovered from `origin.dx * 2` at the paint site, because
  /// upstream's root is wider than the chart whenever the caller passes a
  /// `width` (`useGaugeChartStyles.styles.ts:35-43`) and the two are then not
  /// the same number.
  final Size size;

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

/// The visible or accessible label for one gauge segment.
///
/// A literal port of `getSegmentLabel` (`GaugeChart.tsx:55-71`). The share form
/// appears only when the scale starts at zero **and** the variant is the
/// single-segment one; every other combination shows the range. The percentage
/// goes through `Number.prototype.toFixed()` with no argument (`:64`, `:69`),
/// which is zero decimal places, so [d3.jsRound] supplies JavaScript's half-up
/// rounding before the string is built.
String fluentGaugeSegmentLabel(
  FluentGaugeSegment segment,
  double minValue,
  double maxValue,
  FluentGaugeChartVariant variant, {
  required bool forSemantics,
}) {
  final isShareForm =
      minValue == 0 && variant == FluentGaugeChartVariant.singleSegment;
  // GaugeChart.tsx:64 and :69 — the same percentage in both arms. The literal
  // 100 is the percent conversion, not a tuning value.
  final percent = d3.jsRound(segment.size / maxValue * 100).toStringAsFixed(0);
  final size = d3.jsNumberToString(segment.size);
  final start = d3.jsNumberToString(segment.start);
  final end = d3.jsNumberToString(segment.end);
  if (forSemantics) {
    return isShareForm
        // GaugeChart.tsx:63-64.
        ? '${segment.legend}, $size out of '
              '${d3.jsNumberToString(maxValue)} or $percent%'
        // GaugeChart.tsx:65.
        : '${segment.legend}, $start to $end';
  }
  return isShareForm
      // GaugeChart.tsx:69 — no space before the bracket.
      ? '$size ($percent%)'
      // GaugeChart.tsx:70 — spaces round the dash.
      : '$start - $end';
}

/// The chart value, either painted in the middle of the arc or read out in the
/// popover.
///
/// A literal port of `getChartValueLabel` (`GaugeChart.tsx:73-97`). The two
/// forms are deliberately opposites: whichever of fraction and percentage is
/// painted, the popover shows the other, so the two together disclose the value
/// without repeating it (`GaugeChart.tsx:81-82`). [format] is either a
/// [FluentGaugeValueFormat] or a `String Function(double swept, double span)`
/// standing in for upstream's `(sweepFraction: [number, number]) => string`;
/// the callback arm is ignored for the popover, exactly as upstream ignores it
/// (`:80-88`).
String fluentGaugeValueLabel(
  double chartValue,
  double minValue,
  double maxValue,
  Object? format, {
  required bool forCallout,
}) {
  final value = d3.jsNumberToString(chartValue);
  final max = d3.jsNumberToString(maxValue);
  // GaugeChart.tsx:86 and :96 — the percentage is of maxValue, not of the span.
  final percent = d3.jsRound(chartValue / maxValue * 100).toStringAsFixed(0);
  if (forCallout) {
    if (minValue != 0) {
      // GaugeChart.tsx:83-84 — a non-zero minimum drops both decorations.
      return value;
    }
    return format == FluentGaugeValueFormat.fraction
        // GaugeChart.tsx:86 — the fraction is painted, so the callout inverts.
        ? '$percent%'
        // GaugeChart.tsx:87.
        : '$value/$max';
  }
  if (format is String Function(double, double)) {
    // GaugeChart.tsx:90-91 — the callback receives the SWEPT amount and the
    // span, not the raw value and maximum.
    return format(chartValue - minValue, maxValue - minValue);
  }
  if (minValue != 0) {
    // GaugeChart.tsx:92-93.
    return value;
  }
  return format == FluentGaugeValueFormat.fraction
      // GaugeChart.tsx:95.
      ? '$value/$max'
      // GaugeChart.tsx:96 — the default is the percentage.
      : '$percent%';
}

/// Applies one [FluentGaugeChartStyle] to every [FluentGaugeChart] below it.
class FluentGaugeChartTheme extends InheritedTheme {
  /// Applies [style] to every [FluentGaugeChart] in [child].
  const FluentGaugeChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the resolved defaults.
  final FluentGaugeChartStyle style;

  /// The nearest gauge chart style, or null.
  static FluentGaugeChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentGaugeChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentGaugeChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentGaugeChartTheme(style: style, child: child);
}

/// A Fluent 2 gauge chart: a half-disc of segments with a needle.
///
/// Ports `GaugeChart.tsx`. The widget declares no intrinsic size beyond the
/// style's fallbacks; wrap it in a [SizedBox] to pin one, per design spec §2.2.
class FluentGaugeChart extends StatefulWidget {
  /// Creates a gauge chart.
  const FluentGaugeChart({
    super.key,
    required this.chartValue,
    required this.segments,
    this.minValue = 0,
    this.maxValue,
    this.width,
    this.height,
    this.chartTitle,
    this.sublabel,
    this.hideMinMax = false,
    this.chartValueFormat,
    this.hideLegend = false,
    this.hideTooltip = false,
    this.culture,
    this.variant = FluentGaugeChartVariant.multipleSegments,
    this.roundCorners = false,
    this.canSelectMultipleLegends = false,
    this.style,
  });

  /// Where the needle points, in the same units as the segments.
  final double chartValue;

  /// The segments, in sweep order from the minimum.
  final List<FluentGaugeChartSegment> segments;

  /// The value at the left end of the arc (`GaugeChart.tsx:183`).
  final double minValue;

  /// The value at the right end. When it exceeds the segment total an
  /// `Unknown` filler segment covers the difference (`GaugeChart.tsx:200-209`).
  final double? maxValue;

  /// An explicit width, overriding the incoming constraints.
  final double? width;

  /// An explicit height, overriding the incoming constraints.
  final double? height;

  /// The visible title, painted above the arc (`GaugeChart.tsx:600-609`).
  final String? chartTitle;

  /// A caption below the chart value (`GaugeChart.tsx:685-698`).
  final String? sublabel;

  /// Hides both limit labels, which also shrinks the side margins to the bare
  /// gauge margin (`GaugeChart.tsx:109-112`).
  final bool hideMinMax;

  /// Either a [FluentGaugeValueFormat] or a
  /// `String Function(double swept, double span)`.
  final Object? chartValueFormat;

  /// Hides the legend strip and reclaims its height (`GaugeChart.tsx:119`).
  final bool hideLegend;

  /// Suppresses the popover entirely (`GaugeChart.tsx:703`).
  final bool hideTooltip;

  /// The locale tag upstream passes to `formatToLocaleString` for popover text
  /// (`GaugeChart.tsx:456`).
  ///
  /// `// parity:` not applied — every string this chart puts in the popover is
  /// already formatted by [fluentGaugeSegmentLabel] or
  /// [fluentGaugeValueLabel], both of which build their own text, so upstream's
  /// extra pass over the finished string is a no-op it never notices.
  final String? culture;

  /// Chooses the segment-label form (`GaugeChart.tsx:63`, `:68`).
  final FluentGaugeChartVariant variant;

  /// Rounds the arc ends (`GaugeChart.tsx:214`).
  final bool roundCorners;

  /// Allows more than one legend to stay selected (`GaugeChart.tsx:322-326`).
  final bool canSelectMultipleLegends;

  /// The style layered over [FluentGaugeChartTheme] and the resolved defaults.
  final FluentGaugeChartStyle? style;

  @override
  State<FluentGaugeChart> createState() => _FluentGaugeChartState();
}

/// The name upstream gives the needle when it opens the popover, and the one
/// value of `focusedElement` that is never a legend (`GaugeChart.tsx:399`).
const String _kNeedleAnchor = 'Needle';

class _FluentGaugeChartState extends State<FluentGaugeChart> {
  List<String> _selectedLegends = const <String>[];
  String _hoveredLegend = '';
  String? _focusedElement;
  Offset? _anchor;
  List<FluentYValueHover> _hoverValues = const <FluentYValueHover>[];
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  @override
  void didUpdateWidget(FluentGaugeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // GaugeChart.tsx:155-163 — the selection resets only when the incoming
    // list actually differs, compared element-wise.
    final incoming = <String>[
      for (final segment in widget.segments) segment.legend,
    ];
    if (!areArraysEqual(incoming, <String>[
      for (final segment in oldWidget.segments) segment.legend,
    ])) {
      _selectedLegends = const <String>[];
    }
  }

  List<String> get _highlighted => _selectedLegends.isNotEmpty
      ? _selectedLegends
      : (_hoveredLegend.isEmpty ? const <String>[] : <String>[_hoveredLegend]);

  bool _isDimmed(String legend) =>
      _highlighted.isNotEmpty &&
      !isLegendHighlightedMulti(
        legend,
        selectedLegends: _selectedLegends,
        activeLegend: _hoveredLegend.isEmpty ? null : _hoveredLegend,
      );

  /// How many bands the gauge ends up with, filler included.
  ///
  /// Duplicates the tail of `_processProps` (`GaugeChart.tsx:184-209`) rather
  /// than reading [FluentGaugeLayout.segments], because the region label that
  /// needs it is hoisted above the [LayoutBuilder]: a semantics node inside the
  /// builder is not the widget's own render object, and `getSemantics` would
  /// walk past it to the app's.
  int get _segmentCount {
    // GaugeChart.tsx:186 — the running total is seeded with the minimum.
    var total = widget.minValue;
    for (final segment in widget.segments) {
      // GaugeChart.tsx:189 — Math.max(segment.size, 0).
      total += math.max(segment.size, 0.0);
    }
    // GaugeChart.tsx:203 — a strict `<`, so a maximum exactly at the total
    // appends nothing.
    final hasFiller = widget.maxValue != null && total < widget.maxValue!;
    return widget.segments.length + (hasFiller ? 1 : 0);
  }

  void _showPopover(String legend, Rect bounds, FluentGaugeLayout layout) {
    // GaugeChart.tsx:399-401 — the needle always opens the popover; a segment
    // opens it only while it is not dimmed.
    if (legend != _kNeedleAnchor && _isDimmed(legend)) {
      return;
    }
    setState(() {
      _anchor = bounds.center;
      // GaugeChart.tsx:389-397 — every segment that is not dimmed, in order.
      _hoverValues = <FluentYValueHover>[
        for (final segment in layout.segments)
          if (!_isDimmed(segment.legend))
            FluentYValueHover(
              legend: segment.legend,
              // GaugeChart.tsx:99-101 widens YValueHover.y to a string for
              // this chart alone; the port keeps `y` numeric and carries the
              // label in `yAxisCalloutData`, the slot both callout bodies
              // already prefer over `y` (`GaugeChart.tsx:543`,
              // `ChartPopover.tsx:232`).
              yAxisCalloutText: fluentGaugeSegmentLabel(
                segment,
                layout.minValue,
                layout.maxValue,
                widget.variant,
                forSemantics: false,
              ),
              color: segment.colour,
            ),
      ];
    });
  }

  void _hidePopover() {
    setState(() {
      _anchor = null;
      _hoverValues = const <FluentYValueHover>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resolved = resolveFluentGaugeChartStyle(
      theme,
    ).merge(FluentGaugeChartTheme.maybeOf(context)).merge(widget.style);
    const states = <WidgetState>{};
    final textStyles = FluentChartTextStyles.of(theme);
    final chartColours = FluentChartColors.of(theme);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = fluentL10n(context);

    return Semantics(
      container: true,
      // The gauge's own children carry roles upstream — `option` on each band,
      // `img` on the needle and the limits — so they must stay separate nodes
      // instead of being folded into the region's label.
      explicitChildNodes: true,
      // GaugeChart.tsx:577-579 — the title prefix, then the count, then a
      // trailing space that upstream also emits.
      label:
          '${widget.chartTitle == null ? '' : '${widget.chartTitle}. '}'
          '${l10n.gaugeChartDescription(_segmentCount)}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = FluentGaugeLayout.compute(
            size: Size(
              widget.width ??
                  (constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : resolved.intrinsicWidth!.resolve(states)!),
              widget.height ??
                  (constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : resolved.intrinsicHeight!.resolve(states)!),
            ),
            segments: widget.segments,
            minValue: widget.minValue,
            maxValue: widget.maxValue,
            hasTitle: widget.chartTitle != null,
            hasSublabel: widget.sublabel != null,
            hideMinMax: widget.hideMinMax,
            hideLegend: widget.hideLegend,
            gaugeMargin: resolved.gaugeMargin!.resolve(states)!,
            labelWidth: resolved.labelWidth!.resolve(states)!,
            labelHeight: resolved.labelHeight!.resolve(states)!,
            labelOffset: resolved.labelOffset!.resolve(states)!,
            titleOffset: resolved.titleOffset!.resolve(states)!,
            extraNeedleLength: resolved.extraNeedleLength!.resolve(states)!,
            legendsHeight: widget.hideLegend
                ? 0
                : resolved.legendsHeight!.resolve(states)!,
            unknownColour: resolved.unknownSegmentColor!.resolve(states)!,
            unknownLegend: l10n.gaugeUnknownSegment,
            isDark: theme.brightness == Brightness.dark,
          );
          final arcs = fluentGaugeArcs(
            layout,
            arcPadding: resolved.arcPadding!.resolve(states)!,
            // GaugeChart.tsx:214 — 3 when roundCorners is set, otherwise 0.
            cornerRadius: widget.roundCorners
                ? resolved.cornerRadius!.resolve(states)!
                : 0,
            isRtl: isRtl,
          );
          final valueLabel = fluentGaugeValueLabel(
            widget.chartValue,
            layout.minValue,
            layout.maxValue,
            widget.chartValueFormat,
            forCallout: false,
          );
          final chartValueStyle =
              (resolved.chartValueTextStyle!.resolve(states) ??
                      textStyles.chartTitle)
                  // GaugeChart.tsx:678 — the breakpoint drives the size, not
                  // the class.
                  .copyWith(fontSize: layout.chartValueFontSize);
          final sublabelStyle =
              resolved.sublabelTextStyle!.resolve(states) ??
              textStyles.axisTick;
          final rotation = FluentGaugeLayout.needleRotation(
            widget.chartValue,
            layout.minValue,
            layout.maxValue,
          );

          // GaugeChart.tsx:681 — the chart value is clipped to the hole minus
          // the 24px inset, then ellipsised by _wrapContent (:432-434). The 2
          // turns the inner radius into the diameter.
          final shownValue = truncateString(
            valueLabel,
            _fitCharacters(
              valueLabel,
              chartValueStyle,
              layout.innerRadius * 2 -
                  resolved.chartValueInset!.resolve(states)!,
            ),
          );
          // GaugeChart.tsx:695 — the sublabel gets the whole hole.
          final shownSublabel = widget.sublabel == null
              ? null
              : truncateString(
                  widget.sublabel!,
                  _fitCharacters(
                    widget.sublabel!,
                    sublabelStyle,
                    layout.innerRadius * 2,
                  ),
                );

          final painter = FluentGaugeChartPainter(
            layout: layout,
            arcs: arcs,
            colours: <Color>[
              for (final segment in layout.segments)
                chartColours.flattenMark(segment.colour),
            ],
            // GaugeChart.tsx:646 — 1 when highlighted or nothing is
            // highlighted, otherwise the dimmed 0.1.
            opacities: <double>[
              for (final segment in layout.segments)
                _isDimmed(segment.legend)
                    ? resolved.dimmedOpacity!.resolve(states)!
                    : 1.0,
            ],
            focusedIndex: _focusedElement == null
                ? null
                : layout.segments.indexWhere(
                    (segment) => segment.legend == _focusedElement,
                  ),
            needlePath: fluentGaugeNeedlePath(
              innerRadius: layout.innerRadius,
              needleLength: layout.needleLength,
              extraNeedleLength: resolved.extraNeedleLength!.resolve(states)!,
              strokeWidth: resolved.needleStrokeWidth!.resolve(states)!,
            ),
            // GaugeChart.tsx:247 — right-to-left mirrors the angle, not the
            // path. The 180 is the half disc's own sweep.
            needleRotationDegrees: isRtl ? 180 - rotation : rotation,
            needleFill: resolved.needleFill!.resolve(states)!,
            needleStroke: resolved.needleStroke!.resolve(states)!,
            needleStrokeWidth: resolved.needleStrokeWidth!.resolve(states)!,
            segmentFocusStrokeColour: resolved.segmentFocusStrokeColor!.resolve(
              states,
            )!,
            // GaugeChart.tsx:643 — the focus ring reuses the pad width.
            focusStrokeWidth: resolved.arcPadding!.resolve(states)!,
            minLabel: widget.hideMinMax
                ? null
                : formatScientificLimitWidth(layout.minValue),
            maxLabel: widget.hideMinMax
                ? null
                : formatScientificLimitWidth(layout.maxValue),
            // The value and the sublabel are `SVGTooltipText` upstream
            // (`GaugeChart.tsx:671`, `:686`), not bare `<text>`: both carry a
            // hover tooltip. The port renders those two as widgets for the
            // same reason it renders the title as one, so the painter is told
            // to leave them alone rather than drawing them a second time.
            valueLabel: '',
            sublabel: null,
            labelOffset: resolved.labelOffset!.resolve(states)!,
            limitsTextStyle:
                resolved.limitsTextStyle!.resolve(states) ??
                textStyles.axisTick,
            chartValueTextStyle: chartValueStyle,
            sublabelTextStyle: sublabelStyle,
            measurer: _measurer,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                // GaugeChart.tsx:593-594 sizes the `<svg>` from the `width`
                // PROP, and `useGaugeChartStyles.styles.ts:35-43` makes its
                // root `display: flex; flex-direction: column; align-items:
                // center; width: 100%` — so a chart narrower than the box it
                // is given is CENTRED in it, not pinned to the left edge.
                // `layout.origin` is relative to that svg, so the box handed
                // to the painter has to be the svg's, not the root's.
                //
                // Only the chart area narrows. The legend below stays on the
                // full width, matching `legendsContainer { width: 100% }`
                // (`:126-128`).
                child: Align(
                  child: SizedBox(
                    width: layout.size.width,
                    height: double.infinity,
                    child: MouseRegion(
                      onExit: (_) => _hidePopover(),
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(child: CustomPaint(painter: painter)),
                          if (widget.chartTitle != null)
                            Positioned(
                              left: 0,
                              right: 0,
                              // GaugeChart.tsx:604 — one titleOffset above the arc,
                              // then back up by the row the title occupies.
                              top:
                                  layout.origin.dy -
                                  layout.outerRadius -
                                  resolved.titleOffset!.resolve(states)! -
                                  resolved.labelHeight!.resolve(states)!,
                              child: FluentChartTitle(
                                title: widget.chartTitle!,
                                textStyle:
                                    resolved.titleTextStyle!.resolve(states) ??
                                    textStyles.chartTitle,
                              ),
                            ),
                          for (var i = 0; i < layout.segments.length; i++)
                            _hitTarget(
                              bounds: arcs
                                  .firstWhere((arc) => arc.segmentIndex == i)
                                  .path
                                  .getBounds()
                                  .shift(layout.origin),
                              label: fluentGaugeSegmentLabel(
                                layout.segments[i],
                                layout.minValue,
                                layout.maxValue,
                                widget.variant,
                                forSemantics: true,
                              ),
                              // GaugeChart.tsx:660 — a dimmed segment leaves the
                              // tab order entirely.
                              focusable: !_isDimmed(layout.segments[i].legend),
                              onEnter: (bounds) {
                                _focusedElement = layout.segments[i].legend;
                                _showPopover(
                                  layout.segments[i].legend,
                                  bounds,
                                  layout,
                                );
                              },
                            ),
                          _hitTarget(
                            bounds: painter.needlePath.getBounds().shift(
                              layout.origin,
                            ),
                            // GaugeChart.tsx:275-276 — the non-callout form.
                            label: l10n.gaugeCurrentValue(valueLabel),
                            focusable: true,
                            onEnter: (bounds) =>
                                _showPopover(_kNeedleAnchor, bounds, layout),
                          ),
                          if (!widget.hideMinMax) ...<Widget>[
                            // GaugeChart.tsx:617 and :627 — both limits are
                            // image-role nodes with their own labels.
                            _hitTarget(
                              bounds: _limitBounds(
                                layout,
                                resolved,
                                states,
                                isMaximum: false,
                              ),
                              label: l10n.gaugeMinValue(
                                d3.jsNumberToString(layout.minValue),
                              ),
                              focusable: false,
                              onEnter: null,
                            ),
                            _hitTarget(
                              bounds: _limitBounds(
                                layout,
                                resolved,
                                states,
                                isMaximum: true,
                              ),
                              label: l10n.gaugeMaxValue(
                                d3.jsNumberToString(layout.maxValue),
                              ),
                              focusable: false,
                              onEnter: null,
                            ),
                          ],
                          // GaugeChart.tsx:673-679 — x=0, y=0, text-anchor middle,
                          // the default alphabetic baseline, and `aria-hidden`
                          // because the needle already announces the same string.
                          _centredText(
                            shownValue,
                            chartValueStyle,
                            layout.origin,
                            FluentChartTitleBaseline.alphabetic,
                          ),
                          if (shownSublabel != null)
                            // GaugeChart.tsx:688-692 — x=0, y=4, hanging.
                            _centredText(
                              shownSublabel,
                              sublabelStyle,
                              layout.origin +
                                  Offset(
                                    0,
                                    resolved.labelOffset!.resolve(states)!,
                                  ),
                              FluentChartTitleBaseline.hanging,
                            ),
                          if (_anchor != null && !widget.hideTooltip)
                            Positioned.fill(
                              // The popover follows the cursor, so letting it take
                              // the pointer would pull the pointer off the band
                              // that opened it and close it again.
                              child: IgnorePointer(
                                child: FluentChartPopover(
                                  anchor: _anchor!,
                                  data: FluentChartPopoverData(
                                    // GaugeChart.tsx:386-387 — the callout inverts
                                    // the painted form.
                                    xValue: l10n.gaugeCurrentValueIs(
                                      fluentGaugeValueLabel(
                                        widget.chartValue,
                                        layout.minValue,
                                        layout.maxValue,
                                        widget.chartValueFormat,
                                        forCallout: true,
                                      ),
                                    ),
                                    yValues: _hoverValues,
                                    // GaugeChart.tsx:705-707 passes
                                    // `_multiValueCallout`, which is the stacked
                                    // body.
                                    isCalloutForStack: true,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.hideLegend)
                SizedBox(
                  height: resolved.legendsHeight!.resolve(states)!,
                  // GaugeChart.tsx:283-297 — built from layout.segments, which
                  // already carries the Unknown filler pushed at :200-209.
                  child: FluentChartLegend(
                    centerLegends: true,
                    selectionMode: widget.canSelectMultipleLegends
                        ? FluentChartLegendSelectionMode.multiple
                        : FluentChartLegendSelectionMode.single,
                    selectedLegends: _selectedLegends,
                    legends: <FluentChartLegendItem>[
                      for (final segment in layout.segments)
                        FluentChartLegendItem(
                          title: segment.legend,
                          color: segment.colour,
                          onHoverAction: () =>
                              setState(() => _hoveredLegend = segment.legend),
                          onMouseOutAction: ({required bool isLegendFocused}) =>
                              setState(() => _hoveredLegend = ''),
                        ),
                    ],
                    onChange: (selected, current) => setState(() {
                      // GaugeChart.tsx:322-326 — single selection keeps only
                      // the last entry, upstream's `slice(-1)`.
                      _selectedLegends = widget.canSelectMultipleLegends
                          ? selected
                          : selected
                                .skip(math.max(0, selected.length - 1))
                                .toList(growable: false);
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The box one limit label occupies, outside the arc (`GaugeChart.tsx:613`,
  /// `:623`).
  Rect _limitBounds(
    FluentGaugeLayout layout,
    FluentGaugeChartStyle resolved,
    Set<WidgetState> states, {
    required bool isMaximum,
  }) {
    final offset = resolved.labelOffset!.resolve(states)!;
    final width = resolved.labelWidth!.resolve(states)!;
    final height = resolved.labelHeight!.resolve(states)!;
    return Rect.fromLTWH(
      isMaximum
          ? layout.origin.dx + layout.outerRadius + offset
          : layout.origin.dx - layout.outerRadius - offset - width,
      // The 2 centres the row on the arc's own baseline, which is y = 0.
      layout.origin.dy - height / 2,
      width,
      height,
    );
  }

  /// One `text-anchor: middle` string placed against [anchorPoint] the way
  /// [FluentGaugeChartPainter] would place it, and hidden from assistive tech.
  ///
  /// `aria-hidden="true"` at `GaugeChart.tsx:679`: the needle's own label
  /// already reads the chart value, and the sublabel is decoration.
  Widget _centredText(
    String text,
    TextStyle style,
    Offset anchorPoint,
    FluentChartTitleBaseline baseline,
  ) {
    final metrics = _measurer.measure(text, style);
    return Positioned(
      // The 2 halves the advance width, which is what `text-anchor: middle`
      // does.
      left: anchorPoint.dx - metrics.width / 2,
      top:
          anchorPoint.dy +
          fluentChartBaselineOffset(baseline, metrics) -
          metrics.ascent,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        child: Text(text, style: style, maxLines: 1),
      ),
    );
  }

  /// How many characters of [text] fit in [maxWidth], mirroring
  /// `_wrapContent`'s one-character-at-a-time trim (`GaugeChart.tsx:418-434`).
  int _fitCharacters(String text, TextStyle style, double maxWidth) {
    if (_measurer.width(text, style) <= maxWidth) {
      return text.length;
    }
    for (var length = text.length - 1; length > 0; length--) {
      // The upstream loop measures `content + '...'`, so the ellipsis is inside
      // the budget (`GaugeChart.tsx:427`).
      if (_measurer.width('${text.substring(0, length)}...', style) <=
          maxWidth) {
        return length;
      }
    }
    return 0;
  }

  Widget _hitTarget({
    required Rect bounds,
    required String label,
    required bool focusable,
    required void Function(Rect bounds)? onEnter,
  }) => Positioned.fromRect(
    rect: bounds,
    child: MouseRegion(
      onEnter: onEnter == null ? null : (_) => onEnter(bounds),
      child: Focus(
        canRequestFocus: focusable,
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _focusedElement = null;
            _hidePopover();
          } else if (onEnter != null) {
            onEnter(bounds);
          }
        },
        child: Semantics(
          label: label,
          image: onEnter == null,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}
