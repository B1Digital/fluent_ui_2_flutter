import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../axis/axis_label_layout.dart';
import '../axis/axis_painter.dart';
import '../axis/axis_types.dart';
import '../chrome/chart_title.dart';
import '../internal/chart_colors.dart';
import '../internal/chart_text_measurer.dart';
import '../internal/chart_text_styles.dart';
import '../internal/d3/axis_geometry.dart' as d3;
import 'cartesian_chart_props.dart';
import 'cartesian_chart_style.dart';
import 'cartesian_layout.dart';
import 'cartesian_series_delegate.dart';

/// Paints a cartesian chart in upstream's z-order.
///
/// `CartesianChart.tsx:753-902` emits, in this order: the x-axis group, the
/// x-axis title, the x-axis annotation, the y-axis group with its horizontal
/// gridlines, the secondary y-axis group and its title, then `{children}` —
/// every mark — then the y-axis title and the y-axis annotation. Gridlines
/// therefore sit beneath the series and the y title sits above it, which is
/// visible on any chart whose marks reach the left margin.
class FluentCartesianChartPainter extends CustomPainter {
  /// Creates a painter over an already-solved layout and axis pair.
  FluentCartesianChartPainter({
    required this.layout,
    required this.delegate,
    required this.xAxis,
    required this.yAxisPrimary,
    this.yAxisSecondary,
    required this.xLabelLayout,
    required this.style,
    required this.colors,
    required this.textStyles,
    required this.measurer,
    required this.crispOffset,
    required this.props,
  });

  /// The solved geometry.
  final FluentCartesianLayout layout;

  /// The chart that paints the marks.
  final FluentCartesianSeriesDelegate delegate;

  /// The x axis, already built by one of the three x builders.
  final FluentAxisSpec xAxis;

  /// The primary y axis.
  final FluentAxisSpec yAxisPrimary;

  /// The secondary y axis, or null.
  final FluentAxisSpec? yAxisSecondary;

  /// The wrap / rotate / stagger layout for the x tick labels, or null when no
  /// transformation applies.
  final FluentXAxisLabelLayout? xLabelLayout;

  /// The resolved style.
  final FluentCartesianChartStyle style;

  /// The resolved chart colours.
  final FluentChartColors colors;

  /// The resolved chart type ramp.
  final FluentChartTextStyles textStyles;

  /// The single text measurer for this chart subtree.
  final FluentChartTextMeasurer measurer;

  /// d3-axis's crispness half-pixel: `devicePixelRatio > 1 ? 0 : 0.5`
  /// (`d3-axis/src/axis.js:38`). Added **once** to every tick transform, not
  /// halved — design spec section 5.5.
  final double crispOffset;

  /// The chart's configuration, read here for the four axis titles.
  final FluentCartesianChartProps props;

  /// The font size `CartesianChart.tsx:788` falls back to when no
  /// `titleStyles.titleFont.size` is supplied, which the port never supplies.
  static const double _annotationFallbackFontSize = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final context = FluentCartesianChildContext(
      xScale: xAxis.scale,
      yScalePrimary: yAxisPrimary.scale,
      yScaleSecondary: yAxisSecondary?.scale,
      containerWidth: layout.size.width,
      containerHeight: layout.size.height,
    );

    // 1 — the x-axis group, translated to sit below the plot (`:762-770`).
    _paintAxis(
      canvas,
      size,
      xAxis,
      Offset(0, layout.xAxisTranslateY),
      labelLayout: xLabelLayout,
    );

    // 2 — the x-axis title (`:771-783`).
    _paintTitle(
      canvas,
      props.xAxisTitle,
      anchor: Offset(
        (layout.margins.left ?? 0) +
            kAxisTitlePadding +
            layout.xAxisTitleMaxWidth / 2,
        layout.size.height - kAxisTitlePadding,
      ),
      style: textStyles.axisTitle,
    );

    // 3 — the x-axis annotation (`:784-835`). Without a `titleStyles` bag the
    // upstream defaults stand: font size 13 (`:788`) and
    // `max(fontSize + 8, 20 - 8)` for y (`:803-806`), which is 21.
    _paintTitle(
      canvas,
      props.xAxisAnnotation,
      anchor: Offset(
        (layout.margins.left ?? 0) +
            kAxisTitlePadding +
            layout.xAxisTitleMaxWidth / 2,
        math.max(
          _annotationFallbackFontSize + kAxisTitlePadding,
          kVerticalMarginForXAxisTitle - kAxisTitlePadding,
        ),
      ),
      style: textStyles.axisAnnotation,
    );

    // 4 — the primary y-axis group and its horizontal gridlines (`:836-843`).
    _paintAxis(
      canvas,
      size,
      yAxisPrimary,
      Offset(layout.yAxisTranslateX, 0),
      labelLayout: _yLabelLayout,
    );

    // 5 — the secondary y-axis group and its title (`:844-869`).
    final secondary = yAxisSecondary;
    if (secondary != null) {
      _paintAxis(
        canvas,
        size,
        secondary,
        Offset(layout.secondaryYAxisTranslateX, 0),
      );
      _paintTitle(
        canvas,
        props.secondaryYAxisTitle,
        anchor: Offset(
          layout.secondaryYAxisTitleCenterX,
          layout.yAxisTitleCenterY,
        ),
        style: textStyles.axisTitle,
        rotationRadians: -math.pi / 2,
      );
    }

    // 6 — the marks (`{children}` at `:870`).
    delegate.paintSeries(canvas, context, layout, colors);

    // 7 — the y-axis title, deliberately over the marks (`:871-884`).
    _paintTitle(
      canvas,
      props.yAxisTitle,
      anchor: Offset(layout.yAxisTitleCenterX, layout.yAxisTitleCenterY),
      style: textStyles.axisTitle,
      rotationRadians: -math.pi / 2,
    );

    // 8 — the y-axis annotation, suppressed when a secondary title occupies the
    // same anchor (`:885-901`).
    if (!_isPresent(props.secondaryYAxisTitle)) {
      _paintTitle(
        canvas,
        props.yAxisAnnotation,
        anchor: Offset(
          layout.secondaryYAxisTitleCenterX,
          layout.yAxisTitleCenterY,
        ),
        style: textStyles.axisAnnotation,
        rotationRadians: -math.pi / 2,
      );
    }
  }

  /// The primary y axis's tick labels, truncated when the axis-label tooltip is
  /// on.
  ///
  /// `CartesianChart.tsx:396-406` calls `createYAxisLabels` on `yScalePrimary`
  /// alone — never the secondary — guarded by `props.showYAxisLablesTooltip` and
  /// passing that same flag straight back in as `truncateLabel` (`:404`). The
  /// guard and the argument therefore always agree, so upstream's
  /// `truncateLabel: false` arm has no live call site and the blank axis it
  /// would render (`utilities.ts:1226-1228` sets the tspan text only inside the
  /// branch) never surfaces there.
  ///
  /// The port folds the guard into the argument: one unconditional call whose
  /// `false` arm fills in the whole label, which is exactly the d3 tick text
  /// upstream leaves standing when it skips the call. Both settings match
  /// upstream, and the accessibility arm required by spec section 5.2,
  /// exception 2 becomes the default path rather than unreachable code.
  ///
  /// Without this the left margin and the painted text disagree: `:150-160`
  /// sizes the margin from `truncateString(label, noOfCharsToTruncate)`, which
  /// the shell's `startFromX` solve ports verbatim
  /// (`cartesian_chart.dart:670-686`), so a full label painted into a truncated
  /// label's reserve overruns the chart's left edge.
  ///
  /// A [FluentXAxisLabelLayout] carries the result because that is what
  /// [FluentAxisPainter] accepts; a y axis is never wrapped, staggered or
  /// rotated, so the reserve and the rotation it also carries are zero.
  FluentXAxisLabelLayout get _yLabelLayout => FluentXAxisLabelLayout(
    labels: createYAxisLabels(
      yAxisPrimary.tickLabels,
      props.noOfCharsToTruncate,
      truncateLabel: props.showYAxisLablesTooltip,
      isRtl: layout.isRtl,
    ),
    reserveHeight: 0,
    rotationRadians: 0,
  );

  void _paintAxis(
    Canvas canvas,
    Size size,
    FluentAxisSpec spec,
    Offset translate, {
    FluentXAxisLabelLayout? labelLayout,
  }) {
    canvas
      ..save()
      ..translate(translate.dx, translate.dy);
    FluentAxisPainter(
      geometry: d3.FluentAxisGeometry(
        orientation: spec.orientation,
        scale: spec.scale,
        tickValues: spec.tickValues,
        tickLabels: spec.tickLabels,
        offset: crispOffset,
        tickSizeInner: spec.tickSizeInner,
        tickSizeOuter: spec.tickSizeOuter,
        tickPadding: spec.tickPadding,
      ),
      labelLayout: labelLayout,
      textStyles: textStyles,
      colors: colors,
      measurer: measurer,
      isRtl: layout.isRtl,
    ).paint(canvas, size);
    canvas.restore();
  }

  void _paintTitle(
    Canvas canvas,
    String? text, {
    required Offset anchor,
    required TextStyle style,
    double rotationRadians = 0,
  }) {
    if (!_isPresent(text)) {
      return;
    }
    FluentChartTitlePainter(
      text: text!,
      style: style,
      anchor: anchor,
      textAnchor: d3.FluentAxisTextAnchor.middle,
      baseline: FluentChartTitleBaseline.alphabetic,
      rotationRadians: rotationRadians,
      // `SVGTooltipText` is always given `showBackground: true` by the shell
      // (`CartesianChart.tsx:489`), which draws the backing rect described at
      // `SVGTooltipText.tsx:169-183`.
      showBackground: true,
      backgroundColor: colors.surface,
      measurer: measurer,
    ).paint(canvas, layout.size);
  }

  static bool _isPresent(String? value) => value != null && value != '';

  @override
  bool shouldRepaint(FluentCartesianChartPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      !identical(oldDelegate.delegate, delegate) ||
      !identical(oldDelegate.xAxis, xAxis) ||
      !identical(oldDelegate.yAxisPrimary, yAxisPrimary) ||
      !identical(oldDelegate.yAxisSecondary, yAxisSecondary) ||
      !identical(oldDelegate.xLabelLayout, xLabelLayout) ||
      oldDelegate.style != style ||
      oldDelegate.colors != colors ||
      oldDelegate.crispOffset != crispOffset ||
      // The props bag carries no value equality — 43 fields of it would be
      // boilerplate no test could meaningfully cover — so a rebuilt bag
      // repaints.
      !identical(oldDelegate.props, props);
}
