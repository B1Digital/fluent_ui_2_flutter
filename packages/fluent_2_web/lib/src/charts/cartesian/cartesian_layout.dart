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
