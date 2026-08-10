import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'axis/axis_types.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/scale.dart' as d3;
import 'internal/d3/scale_band.dart' as d3;
import 'model/chart_common.dart';

/// The placement of one category's bar group.
@immutable
class FluentGroupedBarGroupLayout {
  /// Creates a group layout.
  const FluentGroupedBarGroupLayout({
    required this.category,
    required this.translateX,
    required this.effectiveGroupWidth,
    required this.barXByLegend,
  });

  /// The category this group belongs to.
  final String category;

  /// Absolute x the group's local coordinate space starts at.
  final double translateX;

  /// Width the group actually occupies, which shrinks when a legend is absent
  /// from this category (`GroupedVerticalBarChart.tsx:538`).
  final double effectiveGroupWidth;

  /// Bar x offsets relative to [translateX], keyed by legend title.
  final Map<String, double> barXByLegend;
}

/// Pure layout maths for the grouped vertical bar chart.
///
/// Upstream builds **three** band scales: `xScale0` over the categories,
/// `xScale1` over every legend, and a per-group `localScale` over just the
/// legends present in that category. `xScale1` is computed at `.tsx:476` and
/// handed to `_buildGraph`, which never reads it — that scale is dead and is
/// not ported.
abstract final class FluentGroupedVerticalBarChartGeometry {
  /// Inner padding of the per-group bar scale (`X1_INNER_PADDING`, `.tsx:58`).
  static const double kX1InnerPadding = 0.1;

  /// Gap between stacked bars inside one legend column (`VERTICAL_BAR_GAP`,
  /// `.tsx:59`).
  static const double kVerticalBarGap = 1;

  /// Height floor for a bar (`MIN_BAR_HEIGHT`, `.tsx:60`).
  static const double kMinBarHeight = 1;

  /// The default category-scale inner padding.
  ///
  /// `2 / (2 + calcTotalBandUnits(numLegends, 0.1))` (`.tsx:132-136`) — the
  /// comment at `.tsx:129-131` derives it from
  /// `space_between_groups = 2 * bar_width`, so both 2s are that comment's, and
  /// the docs' claim of a flat 2/3 is wrong.
  static double defaultInnerPadding(int legendCount) =>
      2 / (2 + calcTotalBandUnits(legendCount, kX1InnerPadding));

  /// Places one category's group.
  static FluentGroupedBarGroupLayout layOutGroup({
    required String category,
    required List<String> presentLegends,
    required d3.Scale xScale0,
    required double barWidth,
    required bool isRtl,
  }) {
    // GroupedVerticalBarChart.tsx:538.
    final effectiveGroupWidth = calcRequiredWidth(
      barWidth,
      presentLegends.length,
      kX1InnerPadding,
    );
    // GroupedVerticalBarChart.tsx:542-545. The rtl arm reverses the range
    // rather than the domain, so the first legend takes the trailing slot.
    final localScale = d3.scaleBand()
      ..domainOf(presentLegends)
      ..rangeOf(
        isRtl
            ? <double>[effectiveGroupWidth, 0]
            : <double>[0, effectiveGroupWidth],
      )
      ..paddingInner(kX1InnerPadding);
    return FluentGroupedBarGroupLayout(
      category: category,
      // `translate(xScale0(x) + (bandwidth - effectiveGroupWidth) / 2)`
      // (`.tsx:649`); the 2 halves the leftover band width across both sides.
      translateX:
          xScale0(category)! + (xScale0.bandwidth - effectiveGroupWidth) / 2,
      effectiveGroupWidth: effectiveGroupWidth,
      barXByLegend: <String, double>{
        for (final legend in presentLegends)
          // GroupedVerticalBarChart.tsx:551 — the 2 centres the bar in its own
          // slot, which is a no-op while the slot is exactly [barWidth] wide.
          legend:
              (localScale(legend) ?? 0) + (localScale.bandwidth - barWidth) / 2,
      },
    );
  }

  /// Ports `_getDomainMargins` (`GroupedVerticalBarChart.tsx:731-778`).
  ///
  /// Numeric and date x axes fall straight through at [kMinDomainMargin],
  /// because the whole body is inside the `XAxisTypes.StringAxis` guard at
  /// `.tsx:735` and GVBC effectively only supports a category x axis.
  static ({double barWidth, double domainMargin}) solveDomainMargin({
    required int categoryCount,
    required int legendCount,
    required double containerWidth,
    required FluentChartMargins margins,
    required Object? barWidthProp,
    required double? maxBarWidth,
    required double innerPadding,
    required bool isOuterPaddingDefined,
    required String? mode,
    required bool hideTickOverlap,
    required double longestLabelWidth,
  }) {
    var domainMargin = kMinDomainMargin;
    // GroupedVerticalBarChart.tsx:743.
    var barWidth = getBarWidth(barWidthProp, maxBarWidth);
    // GroupedVerticalBarChart.tsx:733.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (isOuterPaddingDefined) {
      // GroupedVerticalBarChart.tsx:736-739.
      domainMargin = 0;
    } else if (barWidthProp != 'auto') {
      // GroupedVerticalBarChart.tsx:744-746.
      final groupWidth = calcRequiredWidth(
        barWidth,
        legendCount,
        kX1InnerPadding,
      );
      final requiredWidth = calcRequiredWidth(
        groupWidth,
        categoryCount,
        innerPadding,
      );
      if (totalWidth >= requiredWidth) {
        // GroupedVerticalBarChart.tsx:750 — the 2 splits the slack evenly
        // across the two sides.
        domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
      }
      // GroupedVerticalBarChart.tsx:752 — the 1 is upstream's own guard
      // against a single-category plotly chart.
    } else if (mode == 'plotly' && categoryCount > 1) {
      // GroupedVerticalBarChart.tsx:754-757.
      final groupBandwidth = calcBandwidth(
        totalWidth,
        categoryCount,
        innerPadding,
      );
      final barBandwidth = calcBandwidth(
        groupBandwidth,
        legendCount,
        kX1InnerPadding,
      );
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: barBandwidth,
      );
      final groupWidth = calcRequiredWidth(
        barWidth,
        legendCount,
        kX1InnerPadding,
      );
      // GroupedVerticalBarChart.tsx:758-759; the 2 is the same even split.
      final margin1 =
          (totalWidth -
              calcRequiredWidth(groupWidth, categoryCount, innerPadding)) /
          2;
      // `margin2` stays +infinity when hideTickOverlap is set
      // (`.tsx:761-767`), so the label term drops out of the `min` below. The
      // 20 is upstream's own inter-label gap at `.tsx:764`.
      final margin2 = hideTickOverlap
          ? double.infinity
          : (totalWidth -
                    (categoryCount - innerPadding) * (longestLabelWidth + 20)) /
                2;
      // GroupedVerticalBarChart.tsx:769 — the 0 floors a negative solve.
      domainMargin =
          kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }
}
