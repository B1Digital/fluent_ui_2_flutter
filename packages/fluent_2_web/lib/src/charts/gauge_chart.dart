import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'gauge_chart_style.dart';
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
