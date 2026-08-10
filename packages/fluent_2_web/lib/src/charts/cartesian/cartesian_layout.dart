import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../axis/axis_label_layout.dart';
import '../axis/axis_painter.dart';
import '../axis/axis_types.dart';
import '../internal/chart_text_measurer.dart';
import '../model/chart_common.dart';
import '../model/chart_value.dart';
import 'cartesian_chart_props.dart';

/// Solves the shell's margin rectangle.
///
/// Five steps, in this order, from `CartesianChart.tsx:655-719`:
///
/// 1. defaults — top 20, bottom 35, left `max(40, startFromX + 20)`,
///    right 40 when a secondary y-scale exists and 20 otherwise;
/// 2. titles — an x title adds 20 to bottom, a y title adds 24 to left, a
///    secondary y title adds 24 to right;
/// 3. annotations — an x annotation adds 20 to **top**, and a y annotation adds
///    24 to right only when there is no secondary y title;
/// 4. the right-to-left swap of left and right, leaving top and bottom alone;
/// 5. the caller's override, spread last and neither swapped nor clamped.
///
/// Margins are physical left/right throughout, never `EdgeInsetsDirectional`,
/// precisely because step 5 runs after step 4.
abstract final class FluentCartesianMarginSolver {
  /// Solves the margins for [props] at the measured [startFromX].
  ///
  /// [startFromX] is the width of the longest y tick label, or zero when
  /// [FluentCartesianChartProps.showYAxisLables] is off
  /// (`CartesianChart.tsx:96-97`). [isRtl] applies step 4.
  static FluentChartMargins solve({
    required FluentCartesianChartProps props,
    required double startFromX,
    required bool isRtl,
  }) {
    var margins = _defaults(props, startFromX);
    margins = _applyTitleMargins(props, margins);
    margins = _applyAnnotationMargins(props, margins);
    if (isRtl) {
      margins = margins.mirrored;
    }
    return margins.mergeOverride(props.margins);
  }

  /// Step 1 — `_getDefaultMargins` (`CartesianChart.tsx:671-682`).
  static FluentChartMargins _defaults(
    FluentCartesianChartProps props,
    double startFromX,
  ) => FluentChartMargins(
    top: kDefaultMarginNoTicks,
    // Upstream subtracts 5 with the comment "Smaller than the default because
    // it is based on the line height rather than the length of the tick
    // labels" (`CartesianChart.tsx:674-676`).
    bottom: kDefaultMarginWithTicks - 5,
    // The 20 is upstream's "tick size, tick padding, and some extra space"
    // allowance on top of the longest label (`CartesianChart.tsx:677-679`).
    left: math.max(kDefaultMarginWithTicks, startFromX + 20),
    right: props.secondaryYScaleOptions != null
        ? kDefaultMarginWithTicks
        : kDefaultMarginNoTicks,
  );

  /// Step 2 — `_applyTitleMargins` (`CartesianChart.tsx:684-696`).
  ///
  /// Each guard is `!== undefined && !== ''`, so an empty string reads as no
  /// title at all.
  static FluentChartMargins _applyTitleMargins(
    FluentCartesianChartProps props,
    FluentChartMargins margins,
  ) {
    var updated = margins;
    if (_isPresent(props.xAxisTitle)) {
      updated = updated.copyWith(
        bottom: updated.bottom! + kVerticalMarginForXAxisTitle,
      );
    }
    if (_isPresent(props.yAxisTitle)) {
      updated = updated.copyWith(
        left: updated.left! + kHorizontalMarginForYAxisTitle,
      );
    }
    if (_isPresent(props.secondaryYAxisTitle)) {
      updated = updated.copyWith(
        right: updated.right! + kHorizontalMarginForYAxisTitle,
      );
    }
    return updated;
  }

  /// Step 3 — `_applyAnnotationMargins` (`CartesianChart.tsx:698-711`).
  ///
  /// The x annotation grows **top**, not bottom, and does so with the x-title
  /// constant. That is upstream's behaviour, not a transcription slip.
  static FluentChartMargins _applyAnnotationMargins(
    FluentCartesianChartProps props,
    FluentChartMargins margins,
  ) {
    var updated = margins;
    if (_isPresent(props.xAxisAnnotation)) {
      updated = updated.copyWith(
        top: updated.top! + kVerticalMarginForXAxisTitle,
      );
    }
    if (_isPresent(props.yAxisAnnotation) &&
        !_isPresent(props.secondaryYAxisTitle)) {
      updated = updated.copyWith(
        right: updated.right! + kHorizontalMarginForYAxisTitle,
      );
    }
    return updated;
  }

  static bool _isPresent(String? value) => value != null && value != '';
}

/// Solves how much vertical space the x tick labels steal, and how they are
/// laid out to do it.
///
/// This is `_transformXAxisLabels` (`CartesianChart.tsx:614-653`) together with
/// the automatic branch at `:282-293`, ported as a pure function. Upstream
/// computes the same number by writing the axis into the DOM with d3 and then
/// re-measuring it, which is why its value lags a render behind; measuring with
/// a [FluentChartTextMeasurer] instead makes it available in the same frame.
///
/// Returns null when no transformation applies, which is upstream's reserve of
/// zero and tells [FluentAxisPainter] to use the geometry's own tick labels.
///
/// The branch order is load-bearing:
///
/// * [tickLayout] of [FluentTickLayout.auto] short-circuits both other
///   branches;
/// * the wrap branch runs when either [FluentCartesianChartProps.wrapXAxisLables]
///   or [FluentCartesianChartProps.showXAxisLablesTooltip] is set;
/// * the rotate branch runs only when
///   [FluentCartesianChartProps.wrapXAxisLables] is **off**, and it
///   *overwrites* the wrap result rather than adding to it.
FluentXAxisLabelLayout? solveFluentCartesianXAxisLabels({
  required FluentCartesianChartProps props,
  required FluentAxisSpec xAxis,
  required FluentChartAxisType xAxisType,
  required FluentTickLayout tickLayout,
  required List<String>? datasetForXAxisDomain,
  required double containerWidth,
  required double marginBottom,
  required TextStyle textStyle,
  required FluentChartTextMeasurer measurer,
}) {
  if (tickLayout == FluentTickLayout.auto) {
    return autoLayoutXAxisLabels(
      xAxis.tickValues,
      xAxis.tickLabels,
      xAxis.scale,
      containerWidth,
      style: textStyle,
      measurer: measurer,
    );
  }

  FluentXAxisLabelLayout? layout;

  if (props.wrapXAxisLables || props.showXAxisLablesTooltip) {
    // `maxXAxisLabelWidth` is left undefined off a band axis
    // (`CartesianChart.tsx:622-631`), and `createWrapOfXLabels` then falls back
    // to `DEFAULT_WRAP_WIDTH` (`utilities.ts:1127`).
    var width = kDefaultWrapWidth;
    if (xAxisType == FluentChartAxisType.category) {
      width = (datasetForXAxisDomain?.length ?? 0) > 1
          // `CartesianChart.tsx:627` — one band's stride is the space a label
          // may occupy before it collides with its neighbour.
          ? xAxis.scale.step
          // `:629` — a single category owns the whole width.
          : containerWidth;
    }
    layout = wrapXLabels(
      xAxis.tickLabels,
      width: width,
      showXAxisLabelsTooltip: props.showXAxisLablesTooltip,
      noOfCharsToTruncate: props.noOfCharsToTruncate,
      style: textStyle,
      measurer: measurer,
    );
  }

  if (!props.wrapXAxisLables &&
      props.rotateXAxisLables &&
      xAxisType == FluentChartAxisType.category) {
    final rotated = rotateXAxisLabels(
      xAxis.tickLabels,
      // Upstream measures the live tick groups, so the box it rotates is the
      // one this axis's own tick size and padding produced
      // (`utilities.ts:1824`); the port hands them over rather than assuming
      // d3-axis's defaults, which the shell replaces when
      // `showXAxisLablesTooltip` drops the padding to 5
      // (`CartesianChart.tsx:215`).
      tickSizeInner: xAxis.tickSizeInner,
      tickPadding: xAxis.tickPadding,
      style: textStyle,
      measurer: measurer,
    );
    layout = FluentXAxisLabelLayout(
      labels: rotated.labels,
      // `CartesianChart.tsx:651` reuses the bottom margin as padding beneath
      // the rotated text, with the comment "margins.bottom is used as padding
      // here". It overwrites the wrap reserve; it does not accumulate.
      reserveHeight: rotated.reserveHeight + marginBottom,
      rotationRadians: rotated.rotationRadians,
      rotationTranslateY: rotated.rotationTranslateY,
    );
  }

  return layout;
}

/// Everything the shell knows about where things go, solved once per build.
///
/// Held by the cartesian painter and handed to every series delegate, which is
/// strictly more information than upstream's render prop supplies: React charts
/// recover the margins through a `getmargins` callback stashed in a closure
/// (`HorizontalBarChartWithAxis.tsx:121-123`), and passing the layout removes
/// that mutation channel entirely.
@immutable
class FluentCartesianLayout {
  /// Creates a layout from already-solved numbers. Prefer
  /// [FluentCartesianLayout.resolve], which derives the ten dependent values
  /// from the three independent ones.
  const FluentCartesianLayout({
    required this.size,
    required this.margins,
    required this.plotRect,
    required this.xAxisReferenceHeight,
    required this.plotContentHeight,
    required this.xAxisLabelReserve,
    required this.isRtl,
    required this.startFromX,
    required this.xAxisTitleMaxWidth,
    required this.yAxisTitleMaxHeight,
    required this.yAxisTitleCenterX,
    required this.yAxisTitleCenterY,
    required this.secondaryYAxisTitleCenterX,
  });

  /// Derives a layout from the measured [size], the solved [margins] and the
  /// x label reserve.
  ///
  /// Every expression here is transcribed from `CartesianChart.tsx:453-485`.
  factory FluentCartesianLayout.resolve({
    required Size size,
    required FluentChartMargins margins,
    required double xAxisLabelReserve,
    required bool isRtl,
    required double startFromX,
  }) {
    final left = margins.left ?? 0;
    final right = margins.right ?? 0;
    final top = margins.top ?? 0;
    final bottom = margins.bottom ?? 0;
    // `AXIS_TITLE_PADDING` is subtracted at both ends, hence the doubling
    // (`CartesianChart.tsx:476-477`).
    final titleMaxWidth = size.width - left - right - kAxisTitlePadding * 2;
    final titleMaxHeight =
        size.height - bottom - top - xAxisLabelReserve - kAxisTitlePadding * 2;
    return FluentCartesianLayout(
      size: size,
      margins: margins,
      plotRect: Rect.fromLTWH(
        left,
        top,
        math.max(0, size.width - left - right),
        math.max(0, size.height - top - bottom - xAxisLabelReserve),
      ),
      // parity: CartesianChart.tsx:209 computes this before the reserve is
      // known, so the subtraction is always of zero. The FIXME at :203-208
      // documents that HBWA and Gantt gridlines are therefore a render stale.
      xAxisReferenceHeight: size.height,
      plotContentHeight: size.height - xAxisLabelReserve,
      xAxisLabelReserve: xAxisLabelReserve,
      isRtl: isRtl,
      startFromX: startFromX,
      xAxisTitleMaxWidth: titleMaxWidth,
      yAxisTitleMaxHeight: titleMaxHeight,
      yAxisTitleCenterX: isRtl
          ? size.width - kAxisTitlePadding
          : kHorizontalMarginForYAxisTitle - kAxisTitlePadding,
      yAxisTitleCenterY: top + kAxisTitlePadding + titleMaxHeight / 2,
      secondaryYAxisTitleCenterX: isRtl
          ? kHorizontalMarginForYAxisTitle - kAxisTitlePadding
          : size.width - kAxisTitlePadding,
    );
  }

  /// The plot box, excluding the legend row.
  final Size size;

  /// The solved margins, already right-to-left swapped and already carrying the
  /// caller's override.
  final FluentChartMargins margins;

  /// The drawable area inside the margins and above the label reserve.
  final Rect plotRect;

  /// `XAxisParams.containerHeight` — the full height, because the reserve is
  /// still zero when upstream computes it (`CartesianChart.tsx:209`). This is
  /// what sizes HorizontalBarChartWithAxis and Gantt vertical gridlines.
  final double xAxisReferenceHeight;

  /// `YAxisParams.containerHeight` — the height with the real reserve removed
  /// (`CartesianChart.tsx:298`). Deliberately distinct from
  /// [xAxisReferenceHeight]; see design spec section 3.3.
  final double plotContentHeight;

  /// `_removalValueForTextTuncate` — the space the x tick labels take.
  final double xAxisLabelReserve;

  /// Whether the chart reads right to left.
  final bool isRtl;

  /// The width of the longest y tick label, or zero when
  /// [FluentCartesianChartProps.showYAxisLables] is off
  /// (`CartesianChart.tsx:96-97`).
  final double startFromX;

  /// Maximum width an x-axis title may occupy (`CartesianChart.tsx:476`).
  final double xAxisTitleMaxWidth;

  /// Maximum length a rotated y-axis title may occupy
  /// (`CartesianChart.tsx:477`).
  final double yAxisTitleMaxHeight;

  /// Horizontal anchor of the primary y-axis title (`CartesianChart.tsx:480`).
  final double yAxisTitleCenterX;

  /// Vertical anchor shared by all three rotated titles
  /// (`CartesianChart.tsx:479`).
  final double yAxisTitleCenterY;

  /// Horizontal anchor of the secondary y-axis title and of the y-axis
  /// annotation (`CartesianChart.tsx:483`).
  final double secondaryYAxisTitleCenterX;

  /// Vertical offset of the x-axis group (`CartesianChart.tsx:768`).
  double get xAxisTranslateY =>
      size.height - (margins.bottom ?? 0) - xAxisLabelReserve;

  /// Horizontal offset of the primary y-axis group
  /// (`CartesianChart.tsx:841`).
  double get yAxisTranslateX =>
      isRtl ? size.width - (margins.right ?? 0) : margins.left ?? 0;

  /// Horizontal offset of the secondary y-axis group — the exact mirror of
  /// [yAxisTranslateX] (`CartesianChart.tsx:851`).
  double get secondaryYAxisTranslateX =>
      isRtl ? margins.left ?? 0 : size.width - (margins.right ?? 0);

  @override
  bool operator ==(Object other) =>
      other is FluentCartesianLayout &&
      other.size == size &&
      other.margins == margins &&
      other.plotRect == plotRect &&
      other.xAxisReferenceHeight == xAxisReferenceHeight &&
      other.plotContentHeight == plotContentHeight &&
      other.xAxisLabelReserve == xAxisLabelReserve &&
      other.isRtl == isRtl &&
      other.startFromX == startFromX &&
      other.xAxisTitleMaxWidth == xAxisTitleMaxWidth &&
      other.yAxisTitleMaxHeight == yAxisTitleMaxHeight &&
      other.yAxisTitleCenterX == yAxisTitleCenterX &&
      other.yAxisTitleCenterY == yAxisTitleCenterY &&
      other.secondaryYAxisTitleCenterX == secondaryYAxisTitleCenterX;

  @override
  int get hashCode => Object.hash(
    size,
    margins,
    plotRect,
    xAxisReferenceHeight,
    plotContentHeight,
    xAxisLabelReserve,
    isRtl,
    startFromX,
    xAxisTitleMaxWidth,
    yAxisTitleMaxHeight,
    yAxisTitleCenterX,
    yAxisTitleCenterY,
    secondaryYAxisTitleCenterX,
  );
}
