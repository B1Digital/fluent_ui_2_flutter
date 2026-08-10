import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'axis/axis_types.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/scale.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// One resolved vertical bar.
@immutable
class FluentVerticalBarRect {
  /// Creates a bar rect.
  const FluentVerticalBarRect({
    required this.rect,
    required this.colour,
    required this.opacity,
    required this.index,
    required this.isNegative,
    required this.labelAnchor,
  });

  /// The bar's rectangle in plot coordinates.
  final Rect rect;

  /// Resolved fill.
  final Color colour;

  /// 1 highlighted, 0.1 dimmed.
  final double opacity;

  /// Index of the source data point.
  final int index;

  /// Whether the bar hangs below the baseline.
  final bool isNegative;

  /// Where the bar's label baseline sits, already offset by 6 above or 12
  /// below (`VerticalBarChart.tsx:965`).
  final Offset labelAnchor;
}

/// Pure layout maths for the vertical bar chart.
///
/// Split out from the delegate so every literal below is asserted without a
/// canvas. Ports `VerticalBarChart.tsx:398-413`, `:626-632` and `:976-1064`.
abstract final class FluentVerticalBarChartGeometry {
  /// Ports `_calculateMinBarHeight` (`VerticalBarChart.tsx:626-632`).
  ///
  /// The result is a *pixel floor*: a bar shorter than this is stretched up to
  /// it so a tiny value stays visible. Note the ratio is against 100, not
  /// against the plot height, so it scales with the y range.
  ///
  /// [yBarScale] is the scale `_getScales` builds at
  /// `VerticalBarChart.tsx:584-586` — the data domain onto `[0, plotHeight]`,
  /// so it answers in pixels. Upstream feeds it a *magnitude* rather than a
  /// domain value, which for a domain that does not start at 0 extrapolates;
  /// that is reproduced, not corrected.
  static double minBarHeight({
    required double yMin,
    required double yMax,
    required double yReferencePoint,
    required Scale yBarScale,
  }) {
    // VerticalBarChart.tsx:627-630. The 0 is upstream's own `yMax < 0`.
    final maxHeightFromBaseline = yMax < 0
        ? (yMin - yReferencePoint).abs()
        : math.max(
            (yMax - yReferencePoint).abs(),
            (yMin - yReferencePoint).abs(),
          );
    // 100.0 is upstream's literal divisor at :631, not a percentage of
    // anything.
    return (yBarScale(maxHeightFromBaseline)! / 100.0).ceilToDouble();
  }

  /// Ports `_getDomainMargins` (`VerticalBarChart.tsx:976-1064`).
  ///
  /// Returns both outputs because upstream writes `_barWidth` and
  /// `_domainMargin` into the same closure and the two are mutually dependent:
  /// the bar width comes from the bandwidth, the bandwidth from the margin.
  ///
  /// [isOuterPaddingDefined] is `isScalePaddingDefined(props.xAxisOuterPadding,
  /// props.xAxisPadding)` (`:995`), hoisted to a flag because [outerPadding]
  /// alone cannot tell an explicit 0 from an absent value. [longestLabelWidth]
  /// is `calculateLongestLabelWidth(uniqueX)` (`:1020`), hoisted because it
  /// needs a text measurer this pure function must not own.
  static ({double barWidth, double domainMargin}) solveDomainMargin({
    required FluentChartAxisType xAxisType,
    required int uniqueXCount,
    required double containerWidth,
    required FluentChartMargins margins,
    required Object? barWidthProp,
    required double? maxBarWidth,
    required double innerPadding,
    required double outerPadding,
    required bool isOuterPaddingDefined,
    required String? mode,
    required double longestLabelWidth,
    required List<Object> sortedXValues,
  }) {
    // VerticalBarChart.tsx:977.
    var domainMargin = kMinDomainMargin;
    var barWidth = getBarWidth(barWidthProp, maxBarWidth, mode: mode);
    // vbc-utils.ts:46 via VerticalBarChart.tsx:990 — the two
    // MIN_DOMAIN_MARGINs are subtracted up front.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (xAxisType == FluentChartAxisType.category) {
      if (isOuterPaddingDefined) {
        // VerticalBarChart.tsx:996 — xAxisOuterPadding now does this job.
        domainMargin = 0;
      } else if (barWidthProp != 'auto' && mode != 'histogram') {
        // VerticalBarChart.tsx:1000.
        barWidth = getBarWidth(barWidthProp, maxBarWidth);
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        // VerticalBarChart.tsx:1005-1006.
        if (totalWidth >= requiredWidth) {
          domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
        }
      } else if ((mode == 'plotly' || mode == 'histogram') &&
          uniqueXCount > 1) {
        // VerticalBarChart.tsx:1010-1025. The 1 is upstream's own
        // `uniqueX.length > 1`.
        final bandwidth = calcBandwidth(totalWidth, uniqueXCount, innerPadding);
        barWidth = getBarWidth(
          barWidthProp,
          maxBarWidth,
          adjustedValue: bandwidth,
          mode: mode,
        );
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        final margin1 = (totalWidth - requiredWidth) / 2;
        // `Number.POSITIVE_INFINITY` at VerticalBarChart.tsx:1015, the seed a
        // `Math.min` fold needs.
        var margin2 = double.infinity;
        if (mode != 'histogram') {
          // +20 is the label breathing room at VerticalBarChart.tsx:1020.
          final step = longestLabelWidth + 20;
          margin2 = (totalWidth - (uniqueXCount - innerPadding) * step) / 2;
        }
        // VerticalBarChart.tsx:1025. The 0 is upstream's own floor.
        domainMargin =
            kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
      }
    } else {
      if (mode == 'histogram') {
        // VerticalBarChart.tsx:1030-1034. `props.maxBarWidth!` is asserted
        // non-null upstream; the fallback keeps a null caller off a crash.
        domainMargin += math.max(
          0.0,
          (totalWidth -
                  calcRequiredWidth(
                    maxBarWidth ?? kDefaultBarWidth,
                    uniqueXCount,
                    innerPadding,
                  )) /
              2,
        );
      }
      // VerticalBarChart.tsx:1045-1054.
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: calculateAppropriateBarWidth(
          sortedXValues,
          calcTotalWidth(containerWidth, margins, domainMargin),
          innerPadding,
        ),
        mode: mode,
      );
      // parity: VerticalBarChart.tsx:1055-1056 are two identical lines, so the
      // margin grows by a whole bar width, not half of one.
      domainMargin += barWidth / 2;
      domainMargin += barWidth / 2;
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }

  /// Ports `_createColors` (`VerticalBarChart.tsx:398-413`).
  ///
  /// Divergence, recorded: upstream builds `scaleLinear<string>()` whose range
  /// is CSS custom-property *strings*, which `d3-color` cannot parse, so d3
  /// falls back to `interpolateString` — an interpolation over the digits
  /// inside the token names, which the browser then resolves. Because Flutter
  /// has no CSS variables, this port resolves the tokens to concrete colours
  /// first and interpolates in sRGB, matching what the browser actually
  /// paints for the single-stop case and every stop boundary.
  static Color colourFor(
    double y, {
    required List<Color> palette,
    required double yMax,
  }) {
    // VerticalBarChart.tsx:399 — an increment of 1 collapses the domain, so a
    // ramp of one entry is constant. The 1 is upstream's own `length <= 1`.
    if (palette.length <= 1) {
      return palette.isEmpty ? const Color(0x00000000) : palette.first;
    }
    final increment = 1 / (palette.length - 1);
    // VerticalBarChart.tsx:407-410.
    final domain = <double>[
      for (var i = 0; i < palette.length; i++) increment * i * yMax,
    ];
    // d3-scale/src/continuous.js clamps nothing, but the range here is a
    // colour list, so beyond either end d3 returns the end stop.
    if (y <= domain.first) {
      return palette.first;
    }
    if (y >= domain.last) {
      return palette.last;
    }
    // 1 is the first interior stop: every y here is above domain.first.
    for (var i = 1; i < domain.length; i++) {
      if (y <= domain[i]) {
        final span = domain[i] - domain[i - 1];
        // The 0 keeps a zero-width segment off a division by zero, which
        // `yMax == 0` produces.
        final t = span == 0 ? 0.0 : (y - domain[i - 1]) / span;
        return Color.lerp(palette[i - 1], palette[i], t)!;
      }
    }
    return palette.last;
  }
}
