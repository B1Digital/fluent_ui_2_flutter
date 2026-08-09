import 'package:flutter/widgets.dart';

import '../internal/chart_colors.dart';
import '../internal/chart_text_measurer.dart';
import '../internal/chart_text_styles.dart';
import '../internal/d3/axis_geometry.dart' as d3;
import 'axis_label_layout.dart';

/// Paints one axis: its tick lines, its gridlines and its labels.
///
/// The geometry comes pre-solved from [d3.FluentAxisGeometry], which is a direct
/// re-derivation of d3-axis's numbers, and the labels from
/// [FluentXAxisLabelLayout] when the axis has been wrapped, rotated or
/// staggered.
///
/// The domain path is **not** drawn: upstream hides it with
/// `& path { display: none }` (`useCartesianChartStyles.styles.ts:73-75` and
/// `:88-90`). [d3.FluentAxisGeometry.domainPath] still computes it so the
/// SVG-geometry oracle can compare against the real implementation.
class FluentAxisPainter extends CustomPainter {
  /// Creates an axis painter over already-resolved geometry and colours.
  const FluentAxisPainter({
    required this.geometry,
    required this.labelLayout,
    required this.textStyles,
    required this.colors,
    required this.measurer,
    required this.isRtl,
  });

  /// The tick positions, line endpoints and label anchors.
  final d3.FluentAxisGeometry geometry;

  /// The transformed labels, or null to paint
  /// [d3.FluentAxisGeometry.tickLabels] on one line each.
  final FluentXAxisLabelLayout? labelLayout;

  /// The resolved chart text styles; only [FluentChartTextStyles.axisTick] is
  /// read here.
  final FluentChartTextStyles textStyles;

  /// The resolved chart colours.
  final FluentChartColors colors;

  /// The shared text measurer, used for the per-line advance widths and
  /// baselines.
  final FluentChartTextMeasurer measurer;

  /// Whether the surrounding chart is right-to-left, which mirrors the label
  /// anchor for a band y axis.
  ///
  /// The mirroring itself happens in the surrounding layout, which flips the
  /// whole plot; the flag is held here because it is part of the repaint
  /// identity.
  final bool isRtl;

  @override
  void paint(Canvas canvas, Size size) {
    final style = textStyles.axisTick;
    // 10 is the axis-tick font size upstream falls back to in its own canvas
    // ruler, `600 10px "Segoe UI"` (`utilities.ts:1267`); it is only reachable
    // here if a theme ships a caption2Strong with no size at all.
    final fontSize = style.fontSize ?? 10;
    final linePaint = Paint()
      // 0.2 is the opacity every axis line carries at
      // useCartesianChartStyles.styles.ts:68 and :85. The gridline colour is
      // the same token, so FluentChartColors.gridLine is deliberately unused
      // here. FluentChartColors.axisTick already carries the 0.2, and
      // Color.withValues replaces the alpha rather than multiplying it, so
      // restating it here is idempotent and keeps the number next to its
      // citation.
      ..color = colors.axisTick.withValues(alpha: 0.2)
      // The CSS declares width: '1px', which is not a stroke property and is
      // dropped, leaving the SVG default stroke-width of 1.
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final ticks = geometry.ticks;
    final rotation = labelLayout?.rotationRadians ?? 0;
    // rotateXAxisLabels translates the tick group down by maxHeight / 2 before
    // rotating (utilities.ts:1839), and reserveHeight is
    // floor(maxHeight / 1.414), so this recovers maxHeight to within 0.71
    // logical pixels.
    // ponytail: derived rather than added to FluentXAxisLabelLayout, which the
    // cross-plan contract freezes at three fields.
    final rotationShiftY = rotation == 0
        ? 0.0
        : (labelLayout!.reserveHeight * 1.414) / 2;

    for (final (index, tick) in ticks.indexed) {
      if (rotation != 0) {
        canvas
          ..save()
          ..translate(tick.position, rotationShiftY)
          ..rotate(rotation)
          ..drawLine(Offset.zero, tick.lineEnd - tick.lineStart, linePaint);
        _paintLabel(
          canvas,
          index: index,
          tick: tick,
          anchor: tick.labelAnchor - Offset(tick.position, 0),
          style: style,
          fontSize: fontSize,
        );
        canvas.restore();
        continue;
      }
      canvas.drawLine(tick.lineStart, tick.lineEnd, linePaint);
      _paintLabel(
        canvas,
        index: index,
        tick: tick,
        anchor: tick.labelAnchor,
        style: style,
        fontSize: fontSize,
      );
    }
  }

  void _paintLabel(
    Canvas canvas, {
    required int index,
    required d3.FluentAxisTickGeometry tick,
    required Offset anchor,
    required TextStyle style,
    required double fontSize,
  }) {
    final layout = labelLayout;
    final lines = layout != null && index < layout.labels.length
        ? layout.labels[index].lines
        : <FluentAxisLabelLine>[
            FluentAxisLabelLine(text: tick.label, dyEm: tick.baselineDyEm),
          ];

    for (final line in lines) {
      // Every width and every baseline in the subsystem comes from the one
      // measurer, so the label lands where the margin solver reserved room for
      // it. The TextPainter below is a paint vehicle only, configured exactly as
      // FluentChartTextMeasurer.measure configures its own: maxLines 1, no
      // scaling, left-to-right, and the leading dropped off the first ascent and
      // the last descent, because SVG <text> has no line box.
      final metrics = measurer.measure(line.text, style);
      final painter = TextPainter(
        text: TextSpan(text: line.text, style: style),
        maxLines: 1,
        textScaler: TextScaler.noScaling,
        textDirection: TextDirection.ltr,
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      )..layout();
      // axis.js:72 expresses the baseline offset in ems relative to the anchor.
      final baselineY = anchor.dy + line.dyEm * fontSize;
      final top = baselineY - metrics.ascent;
      final left = switch (tick.textAlign) {
        d3.FluentAxisTextAnchor.start => anchor.dx,
        // 2 because text-anchor: middle centres the advance width on the anchor.
        d3.FluentAxisTextAnchor.middle => anchor.dx - metrics.width / 2,
        d3.FluentAxisTextAnchor.end => anchor.dx - metrics.width,
      };
      painter.paint(canvas, Offset(left, top));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(FluentAxisPainter oldDelegate) {
    return !identical(oldDelegate.geometry, geometry) ||
        !identical(oldDelegate.labelLayout, labelLayout) ||
        oldDelegate.textStyles.axisTick != textStyles.axisTick ||
        oldDelegate.colors.axisTick != colors.axisTick ||
        oldDelegate.isRtl != isRtl;
  }
}
