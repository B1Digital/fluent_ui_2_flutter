import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The direction a funnel's stages run in.
///
/// Ports `FunnelChartProps.orientation`
/// (`FunnelChart.types.ts:98`), which defaults to `'horizontal'`.
enum FluentFunnelOrientation {
  /// Stages run left to right, each one a vertical slab whose height carries
  /// the value.
  horizontal,

  /// Stages run top to bottom, each one a horizontal band whose width carries
  /// the value.
  vertical,
}

/// One category inside a stacked funnel stage.
///
/// Ports the anonymous `subValues` element
/// (`FunnelChart.types.ts:20`).
@immutable
class FluentFunnelSubValue {
  /// Creates a sub-value.
  const FluentFunnelSubValue({
    required this.category,
    required this.value,
    this.color,
  });

  /// The category name, matched by identity across stages so a band can be
  /// traced from one stage to the next (`funnelGeometry.ts:161`).
  final String category;

  /// The magnitude this band carries (`FunnelChart.types.ts:20`).
  final double value;

  /// The band's fill, or null to take the palette's colour for its position.
  final Color? color;
}

/// One stage of a funnel.
///
/// Ports `FunnelChartDataPoint` (`FunnelChart.types.ts:11-29`).
@immutable
class FluentFunnelDataPoint {
  /// Creates a stage.
  const FluentFunnelDataPoint({
    required this.stage,
    this.value,
    this.color,
    this.subValues,
  }) : assert(
         stage is num || stage is String,
         'FunnelChart.types.ts:15 — `string | number`.',
       );

  /// The stage's name. A `num` or a [String]
  /// (`FunnelChart.types.ts:15`).
  final Object stage;

  /// The stage's magnitude, read only by a non-stacked funnel
  /// (`FunnelChart.types.ts:24`).
  final double? value;

  /// The stage's fill, read only by a non-stacked funnel
  /// (`FunnelChart.types.ts:28`).
  final Color? color;

  /// The categories this stage splits into, or null when the stage is not
  /// stacked (`FunnelChart.types.ts:20`).
  ///
  /// A funnel is stacked only when *every* stage carries this — see
  /// [isFluentStackedFunnelData].
  final List<FluentFunnelSubValue>? subValues;
}

/// Whether [data] should be drawn as a stacked funnel.
///
/// Ports `isStackedFunnelData` (`FunnelChart.tsx:310-312`) —
/// `data.every(stage => Array.isArray(stage.subValues))`. One stage without
/// sub-values takes the whole chart down the non-stacked path, so this is an
/// all-or-nothing test rather than a per-stage one.
bool isFluentStackedFunnelData(List<FluentFunnelDataPoint> data) =>
    data.every((stage) => stage.subValues != null);

/// One funnel segment's outline and label anchor.
///
/// Ports `FunnelSegmentGeometry` and `StackedFunnelSegmentGeometry`
/// (`funnelGeometry.ts:4-16`), which are the same four fields under two names.
/// The `pathD` string becomes a [Path]; the four generators are
/// [FluentFunnelSegmentGeometry.vertical],
/// [FluentFunnelSegmentGeometry.horizontal],
/// [FluentFunnelSegmentGeometry.stackedVertical] and
/// [FluentFunnelSegmentGeometry.stackedHorizontal].
@immutable
class FluentFunnelSegmentGeometry {
  /// Creates a geometry.
  ///
  /// [path] is null only for a value built to exercise [showText] in isolation:
  /// every generator returns a closed four-vertex outline.
  const FluentFunnelSegmentGeometry({
    required this.path,
    required this.textX,
    required this.textY,
    required this.availableWidth,
  });

  /// The segment's closed outline, in the funnel's own coordinate space.
  final Path? path;

  /// The label anchor's x, which every call site draws centred on.
  final double textX;

  /// The label anchor's y — a baseline, as upstream's `<text y>` is.
  final double textY;

  /// The room the label has, in logical pixels, or zero when a cut-off has
  /// already ruled the label out.
  final double availableWidth;

  /// Whether the segment's value label should be drawn.
  ///
  /// Ports `getSegmentTextProps` (`funnelGeometry.ts:288-328`).
  ///
  /// The signature defaults `minTextWidth` to 24, but both call sites pass 16
  /// (`FunnelChart.tsx:287`, `:348`), so 24 never reaches the comparison.
  bool showText(double minTextWidth) =>
      availableWidth > minTextWidth && availableWidth > 0;

  /// The geometry of the stage at [index] in a vertical, non-stacked funnel.
  ///
  /// Ports `getVerticalFunnelSegmentGeometry` (`funnelGeometry.ts:28-70`).
  static FluentFunnelSegmentGeometry vertical({
    required int index,
    required List<FluentFunnelDataPoint> data,
    required double funnelWidth,
    required double funnelHeight,
    required bool isRtl,
  }) {
    final segmentHeight = funnelHeight / data.length;
    final maxValue = _maxValue(data);
    // funnelGeometry.ts:44.
    double widthScale(double value) => value / maxValue * funnelWidth;
    final topWidth = widthScale(data[index].value ?? 0);
    // funnelGeometry.ts:46 — the last stage tapers to nothing.
    final bottomWidth = index < data.length - 1
        ? widthScale(data[index + 1].value ?? 0)
        : 0.0;
    // funnelGeometry.ts:47-48 — 2 because the funnel is centred.
    final xOffset = (funnelWidth - topWidth) / 2;
    final nextXOffset = (funnelWidth - bottomWidth) / 2;
    final xStart = isRtl ? funnelWidth - xOffset : xOffset;
    final xEnd = isRtl ? funnelWidth - nextXOffset : nextXOffset;

    final isLastSegment = index == data.length - 1;
    // funnelGeometry.ts:53 — the triangular last stage puts its label a third
    // of the way down, every other stage puts it halfway.
    final textY = isLastSegment
        ? index * segmentHeight + segmentHeight * 0.33
        : index * segmentHeight + segmentHeight / 2;

    final textX = funnelWidth / 2;
    final double availableWidth;
    if (isLastSegment) {
      // funnelGeometry.ts:58-60 — the triangle's width at the label row, kept
      // to 0.8 of it.
      final yFromTop = textY - index * segmentHeight;
      final widthAtY = topWidth * (1 - yFromTop / segmentHeight);
      availableWidth = math.max(widthAtY * 0.8, 0);
    } else {
      // funnelGeometry.ts:62 — 0.9 of the trapezium's narrower edge.
      availableWidth = math.min(topWidth, bottomWidth) * 0.9;
    }
    // funnelGeometry.ts:64-68.
    final path = Path()
      ..moveTo(xStart, index * segmentHeight)
      ..lineTo(funnelWidth - xStart, index * segmentHeight)
      ..lineTo(funnelWidth - xEnd, (index + 1) * segmentHeight)
      ..lineTo(xEnd, (index + 1) * segmentHeight)
      ..close();
    return FluentFunnelSegmentGeometry(
      path: path,
      textX: textX,
      textY: textY,
      availableWidth: availableWidth,
    );
  }

  /// The geometry of the stage at [index] in a horizontal, non-stacked funnel.
  ///
  /// Ports `getHorizontalFunnelSegmentGeometry` (`funnelGeometry.ts:72-132`).
  ///
  /// [isRtl] is accepted and never read, exactly as upstream's parameter at
  /// `funnelGeometry.ts:78` is: the whole funnel is mirrored once by the outer
  /// group's transform (`FunnelChart.tsx:505`), never per segment.
  static FluentFunnelSegmentGeometry horizontal({
    required int index,
    required List<FluentFunnelDataPoint> data,
    required double funnelWidth,
    required double funnelHeight,
    required bool isRtl,
  }) {
    final segmentWidth = funnelWidth / data.length;
    final maxValue = _maxValue(data);
    // funnelGeometry.ts:88.
    double heightScale(double value) => value / maxValue * funnelHeight;
    final leftHeight = heightScale(data[index].value ?? 0);
    // funnelGeometry.ts:90 — the last stage tapers to nothing.
    final rightHeight = index < data.length - 1
        ? heightScale(data[index + 1].value ?? 0)
        : 0.0;
    // funnelGeometry.ts:91-92 — 2 because the funnel is centred.
    final yOffset = (funnelHeight - leftHeight) / 2;
    final nextYOffset = (funnelHeight - rightHeight) / 2;
    final x0 = index * segmentWidth;
    final x1 = (index + 1) * segmentWidth;

    final isLastSegment = index == data.length - 1;
    final double textX;
    final double textY;
    // funnelGeometry.ts:99 — an initialiser both branches below overwrite,
    // kept so the statement order matches upstream.
    var availableWidth = segmentWidth * 0.8;

    if (isLastSegment) {
      // funnelGeometry.ts:102-103 — the triangular last segment puts its label
      // a quarter of the way in from the left edge.
      textX = x0 + (x1 - x0) * 0.25;
      textY = funnelHeight / 2;

      // funnelGeometry.ts:108-109 — a triangle's area is base * height / 2, and
      // 800 square pixels is upstream's floor for a legible label.
      final segmentArea = leftHeight * segmentWidth / 2;
      const minAreaForText = 800.0;

      if (leftHeight < 40 || segmentArea < minAreaForText) {
        // funnelGeometry.ts:111-113 — under 40 tall, or too small in area, the
        // label goes altogether.
        availableWidth = 0;
      } else {
        // funnelGeometry.ts:116-117 — 0.75 of the column, then 0.6 of that.
        final widthAtTextPosition = (x1 - x0) * 0.75;
        availableWidth = widthAtTextPosition * 0.6;
      }
    } else {
      textX = (x0 + x1) / 2;
      textY = funnelHeight / 2;
      // funnelGeometry.ts:122-123 — strictly greater than 20, so a segment
      // exactly 20 tall at its narrow edge shows nothing.
      final minHeight = math.min(leftHeight, rightHeight);
      availableWidth = minHeight > 20 ? segmentWidth * 0.8 : 0;
    }

    // funnelGeometry.ts:126-130.
    final path = Path()
      ..moveTo(x0, yOffset)
      ..lineTo(x1, nextYOffset)
      ..lineTo(x1, funnelHeight - nextYOffset)
      ..lineTo(x0, funnelHeight - yOffset)
      ..close();
    return FluentFunnelSegmentGeometry(
      path: path,
      textX: textX,
      textY: textY,
      availableWidth: availableWidth,
    );
  }

  /// The geometry of sub-value [subIndex] of stage [stageIndex] in a vertical,
  /// stacked funnel.
  ///
  /// Ports `getStackedVerticalFunnelSegmentGeometry`
  /// (`funnelGeometry.ts:134-200`). [totals] holds each stage's summed
  /// sub-values and [maxTotal] the largest of them.
  static FluentFunnelSegmentGeometry stackedVertical({
    required int stageIndex,
    required int subIndex,
    required List<FluentFunnelDataPoint> stages,
    required List<double> totals,
    required double maxTotal,
    required double funnelWidth,
    required double funnelHeight,
  }) {
    final segmentHeight = funnelHeight / stages.length;
    final cur = _subValues(stages, stageIndex);
    // funnelGeometry.ts:153 — `stages[i + 1] || { subValues: [] }`.
    final next = _subValues(stages, stageIndex + 1);
    // funnelGeometry.ts:154-155 — `totals[i] || 1` and `totals[i + 1] || 0`.
    final curTotal = _totalOr(totals, stageIndex, 1);
    final nextTotal = _totalOr(totals, stageIndex + 1, 0);

    var cumTop = 0.0;
    var cumBot = 0.0;
    for (var idx = 0; idx < subIndex; idx++) {
      final v = cur[idx];
      final nextVal = _valueOf(next, v.category);
      // funnelGeometry.ts:164-165.
      cumTop += v.value / curTotal * (curTotal / maxTotal) * funnelWidth;
      cumBot +=
          _share(nextVal, nextTotal) * (nextTotal / maxTotal) * funnelWidth;
    }
    final v = cur[subIndex];
    final nextVal = _valueOf(next, v.category);
    // funnelGeometry.ts:171-172.
    final topW = v.value / curTotal * (curTotal / maxTotal) * funnelWidth;
    final botW =
        _share(nextVal, nextTotal) * (nextTotal / maxTotal) * funnelWidth;
    // funnelGeometry.ts:173-176 — 2 because each stage's band is centred.
    final topStart =
        (funnelWidth - curTotal / maxTotal * funnelWidth) / 2 + cumTop;
    final topEnd = topStart + topW;
    final botStart =
        (funnelWidth - nextTotal / maxTotal * funnelWidth) / 2 + cumBot;
    final botEnd = botStart + botW;
    // funnelGeometry.ts:177 — 4, the mean of the trapezium's four x's.
    final textX = (topStart + topEnd + botStart + botEnd) / 4;

    final isLastSegment = stageIndex == stages.length - 1;
    // funnelGeometry.ts:180 — a third of the way down for the last stage,
    // halfway for the rest.
    final textY = isLastSegment
        ? stageIndex * segmentHeight + segmentHeight * 0.33
        : (stageIndex + 0.5) * segmentHeight;

    final double availableWidth;
    if (isLastSegment) {
      // funnelGeometry.ts:186-188 — the triangle's width at the label row.
      final yFromTop = textY - stageIndex * segmentHeight;
      final widthRatio = 1 - yFromTop / segmentHeight;
      availableWidth = topW * widthRatio;
    } else {
      // funnelGeometry.ts:191 — the trapezium's narrower edge, unscaled.
      availableWidth = math.min(topW, botW);
    }

    // funnelGeometry.ts:194-198.
    final path = Path()
      ..moveTo(topStart, stageIndex * segmentHeight)
      ..lineTo(topEnd, stageIndex * segmentHeight)
      ..lineTo(botEnd, (stageIndex + 1) * segmentHeight)
      ..lineTo(botStart, (stageIndex + 1) * segmentHeight)
      ..close();
    return FluentFunnelSegmentGeometry(
      path: path,
      textX: textX,
      textY: textY,
      availableWidth: availableWidth,
    );
  }

  /// The geometry of sub-value [subIndex] of stage [stageIndex] in a
  /// horizontal, stacked funnel.
  ///
  /// Ports `getStackedHorizontalFunnelSegmentGeometry`
  /// (`funnelGeometry.ts:202-286`). See
  /// [FluentFunnelSegmentGeometry.stackedVertical] for [totals] and [maxTotal].
  static FluentFunnelSegmentGeometry stackedHorizontal({
    required int stageIndex,
    required int subIndex,
    required List<FluentFunnelDataPoint> stages,
    required List<double> totals,
    required double maxTotal,
    required double funnelWidth,
    required double funnelHeight,
  }) {
    final segmentWidth = funnelWidth / stages.length;
    final cur = _subValues(stages, stageIndex);
    // funnelGeometry.ts:221 — `stages[i + 1] || { subValues: [] }`.
    final next = _subValues(stages, stageIndex + 1);
    // funnelGeometry.ts:222-223 — `totals[i] || 1` and `totals[i + 1] || 0`.
    final curTotal = _totalOr(totals, stageIndex, 1);
    final nextTotal = _totalOr(totals, stageIndex + 1, 0);

    var cumTop = 0.0;
    var cumBot = 0.0;
    for (var idx = 0; idx < subIndex; idx++) {
      final v = cur[idx];
      final nextVal = _valueOf(next, v.category);
      // funnelGeometry.ts:232-233.
      cumTop += v.value / curTotal * (curTotal / maxTotal) * funnelHeight;
      cumBot +=
          _share(nextVal, nextTotal) * (nextTotal / maxTotal) * funnelHeight;
    }
    final v = cur[subIndex];
    final nextVal = _valueOf(next, v.category);
    // funnelGeometry.ts:239-240.
    final topH = v.value / curTotal * (curTotal / maxTotal) * funnelHeight;
    final botH =
        _share(nextVal, nextTotal) * (nextTotal / maxTotal) * funnelHeight;
    final leftStart = stageIndex * segmentWidth;
    final leftEnd = (stageIndex + 1) * segmentWidth;
    // funnelGeometry.ts:243-246 — 2 because each stage's stack is centred.
    final topStart =
        (funnelHeight - curTotal / maxTotal * funnelHeight) / 2 + cumTop;
    final topEnd = topStart + topH;
    final botStart =
        (funnelHeight - nextTotal / maxTotal * funnelHeight) / 2 + cumBot;
    final botEnd = botStart + botH;

    final isLastSegment = stageIndex == stages.length - 1;
    final double textX;
    final double textY;
    double availableWidth;

    if (isLastSegment) {
      // funnelGeometry.ts:254-258 — a quarter in from the left edge, and half
      // the column scaled by 0.8 for the room.
      textX = leftStart + (leftEnd - leftStart) * 0.25;
      textY = (topStart + topEnd) / 2;
      final segmentWidthAtTextPos = (leftEnd - leftStart) * 0.5;
      availableWidth = segmentWidthAtTextPos * 0.8;

      // funnelGeometry.ts:262-265 — a triangle's area is base * height / 2;
      // under 24 tall or under 600 square pixels the label goes.
      final segmentArea = topH * segmentWidth / 2;
      if (topH < 24 || segmentArea < 600) {
        availableWidth = 0;
      }
    } else {
      textX = (leftStart + leftEnd) / 2;
      // funnelGeometry.ts:268 — 4, the mean of the trapezium's four y's.
      textY = (topStart + topEnd + botStart + botEnd) / 4;
      // funnelGeometry.ts:270 — 0.9 of the full column.
      availableWidth = (leftEnd - leftStart).abs() * 0.9;

      // funnelGeometry.ts:274-277 — under 20 tall on average the label goes.
      final avgHeight = (topH + botH) / 2;
      if (avgHeight < 20) {
        availableWidth = 0;
      }
    }

    // funnelGeometry.ts:280-284.
    final path = Path()
      ..moveTo(leftStart, topStart)
      ..lineTo(leftEnd, botStart)
      ..lineTo(leftEnd, botEnd)
      ..lineTo(leftStart, topEnd)
      ..close();
    return FluentFunnelSegmentGeometry(
      path: path,
      textX: textX,
      textY: textY,
      availableWidth: availableWidth,
    );
  }

  /// `Math.max(...data.map(dataPoint => dataPoint.value!))`
  /// (`funnelGeometry.ts:44`, `:88`).
  static double _maxValue(List<FluentFunnelDataPoint> data) =>
      data.map((point) => point.value ?? 0).reduce((a, b) => a > b ? a : b);

  /// `stages[index] || { subValues: [] }` (`funnelGeometry.ts:153`, `:221`),
  /// which also covers a stage the caller left unstacked.
  static List<FluentFunnelSubValue> _subValues(
    List<FluentFunnelDataPoint> stages,
    int index,
  ) => index < 0 || index >= stages.length
      ? const <FluentFunnelSubValue>[]
      : stages[index].subValues ?? const <FluentFunnelSubValue>[];

  /// `totals[index] || fallback` (`funnelGeometry.ts:154-155`, `:222-223`) —
  /// a zero total is falsy in JavaScript and so takes the fallback, and an
  /// index past the end is `undefined` and does the same.
  static double _totalOr(List<double> totals, int index, double fallback) {
    if (index < 0 || index >= totals.length) {
      return fallback;
    }
    final total = totals[index];
    return total == 0 ? fallback : total;
  }

  /// `next.subValues?.find(x => x.category === category)`, then
  /// `vNext ? vNext.value : 0` (`funnelGeometry.ts:161-163`, `:168-170`).
  static double _valueOf(List<FluentFunnelSubValue> next, String category) {
    for (final candidate in next) {
      if (candidate.category == category) {
        return candidate.value;
      }
    }
    return 0;
  }

  /// The `nextVal / nextTotal` share of the next stage.
  ///
  // funnelGeometry.ts:165,172 parses as ((nextVal / nextTotal) || 0). A zero
  // nextTotal makes that NaN, which JavaScript's falsy guard turns into 0;
  // Dart needs the check written out.
  // parity: funnelGeometry.ts:165,172.
  static double _share(double nextVal, double nextTotal) =>
      nextTotal == 0 ? 0.0 : nextVal / nextTotal;
}
