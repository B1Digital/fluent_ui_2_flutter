import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/grouped_vertical_bar_chart.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `GroupedVerticalBarChart.tsx:607` — the gap above a positive bar's label.
const double kGvbcGapAbove = 6;

/// `GroupedVerticalBarChart.tsx:607` — the gap below a negative bar's label.
const double kGvbcGapBelow = 12;

d3.Scale _bandScale({
  required List<String> domain,
  required List<double> range,
  required double innerPadding,
  required double outerPadding,
}) => d3.scaleBand()
  ..domainOf(domain)
  ..rangeOf(range)
  ..paddingInner(innerPadding)
  ..paddingOuter(outerPadding);

/// The group `<g>` elements of [story], in document order. Each holds one
/// category's bar rects and their labels.
List<OracleElement> _groupElements(OracleStory story) {
  final parents = story.byTag('rect').map((element) => element.parent).toSet();
  return story
      .byTag('g')
      .where((element) => parents.contains(element.index))
      .toList();
}

void main() {
  group('GVBC band scales', () {
    test('the default inner padding is 2 / (2 + totalBandUnits(n, 0.1))', () {
      expect(
        FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(3),
        // The 3 is the legend count under test; both 2s and the 0.1 are
        // upstream's own, from the derivation comment at `.tsx:129-131`.
        closeTo(2 / (2 + (3 + 2 * (0.1 / 0.9))), 1e-12),
        reason:
            'GroupedVerticalBarChart.tsx:132-136 — the docs claim 2/3 and '
            'the code does not',
      );
    });

    test('a group missing a legend re-centres on a narrower group width', () {
      final x0 = _bandScale(
        domain: <String>['a', 'b', 'c'],
        range: <double>[48, 780],
        innerPadding: FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
          3,
        ),
        outerPadding: 0,
      );
      const barWidth = 16.0;
      final full = FluentGroupedVerticalBarChartGeometry.layOutGroup(
        category: 'a',
        presentLegends: <String>['A', 'B', 'C'],
        xScale0: x0,
        barWidth: barWidth,
        isRtl: false,
      );
      final partial = FluentGroupedVerticalBarChartGeometry.layOutGroup(
        category: 'b',
        presentLegends: <String>['A', 'C'],
        xScale0: x0,
        barWidth: barWidth,
        isRtl: false,
      );
      expect(
        full.effectiveGroupWidth,
        closeTo(calcRequiredWidth(barWidth, 3, 0.1), 1e-9),
        reason: 'GroupedVerticalBarChart.tsx:538',
      );
      expect(
        partial.effectiveGroupWidth,
        closeTo(calcRequiredWidth(barWidth, 2, 0.1), 1e-9),
        reason: 'a missing legend shrinks the effective group width',
      );
      expect(
        partial.translateX,
        closeTo(
          // The 2 is upstream's own halving of the leftover band width.
          x0('b')! + (x0.bandwidth - partial.effectiveGroupWidth) / 2,
          1e-9,
        ),
        reason: 'GroupedVerticalBarChart.tsx:649 re-centres each group',
      );
    });

    test('the per-group local scale centres each bar in its own slot', () {
      final x0 = _bandScale(
        domain: <String>['a'],
        range: <double>[48, 780],
        // An arbitrary category padding: this test only reads the local scale.
        innerPadding: 0.38,
        outerPadding: 0,
      );
      final g = FluentGroupedVerticalBarChartGeometry.layOutGroup(
        category: 'a',
        presentLegends: <String>['A', 'B'],
        xScale0: x0,
        barWidth: 16,
        isRtl: false,
      );
      expect(
        g.barXByLegend['A'],
        closeTo(0, 1e-9),
        reason:
            'localScale bandwidth equals _barWidth exactly at paddingInner '
            '0.1, so the centring term is zero — '
            'GroupedVerticalBarChart.tsx:551',
      );
    });

    test('an rtl group lays the legends out right to left', () {
      final x0 = _bandScale(
        domain: <String>['a'],
        range: <double>[0, 100],
        innerPadding: 0.38,
        outerPadding: 0,
      );
      final g = FluentGroupedVerticalBarChartGeometry.layOutGroup(
        category: 'a',
        presentLegends: <String>['A', 'B'],
        xScale0: x0,
        barWidth: 16,
        isRtl: true,
      );
      expect(
        g.barXByLegend['A'],
        // The 16 is this test's own bar width.
        closeTo(g.effectiveGroupWidth - 16, 1e-9),
        reason:
            'GroupedVerticalBarChart.tsx:544 reverses the local range under '
            'rtl, so the first legend takes the trailing slot',
      );
    });
  });

  group('GVBC domain margin', () {
    const margins = FluentChartMargins(left: 40, right: 20);

    test('the string branch centres the whole grid', () {
      final solved = FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
        categoryCount: 3,
        legendCount: 3,
        containerWidth: 800,
        margins: margins,
        barWidthProp: 'default',
        maxBarWidth: 24,
        innerPadding: FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
          3,
        ),
        isOuterPaddingDefined: false,
        mode: null,
        hideTickOverlap: true,
        longestLabelWidth: 0,
      );
      expect(
        solved.domainMargin,
        greaterThanOrEqualTo(kMinDomainMargin),
        reason: 'GroupedVerticalBarChart.tsx:748-751 never goes below 8',
      );
      final groupWidth = calcRequiredWidth(solved.barWidth, 3, 0.1);
      final reqWidth = calcRequiredWidth(
        groupWidth,
        3,
        FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(3),
      );
      expect(
        solved.domainMargin,
        closeTo(
          // The 2 is upstream's split of the slack across the two sides.
          kMinDomainMargin +
              (calcTotalWidth(800, margins, kMinDomainMargin) - reqWidth) / 2,
          1e-9,
        ),
        reason: 'GroupedVerticalBarChart.tsx:750',
      );
    });

    test('a defined outer padding zeroes the margin', () {
      expect(
        FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
          categoryCount: 3,
          legendCount: 3,
          containerWidth: 800,
          margins: margins,
          barWidthProp: 'default',
          maxBarWidth: 24,
          innerPadding: 0.38,
          isOuterPaddingDefined: true,
          mode: null,
          hideTickOverlap: true,
          longestLabelWidth: 0,
        ).domainMargin,
        0,
        reason: 'GroupedVerticalBarChart.tsx:739',
      );
    });

    test('hideTickOverlap removes the label-width term from plotly mode', () {
      // `barWidthProp` must be `'auto'` to reach the plotly branch at all:
      // `GroupedVerticalBarChart.tsx:740` claims every other value for the
      // centring branch above it. The plan's own draft of this test passed
      // `'default'`, which never enters the arm it asserts about.
      final withOverlap =
          FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
            categoryCount: 4,
            legendCount: 2,
            containerWidth: 800,
            margins: margins,
            barWidthProp: 'auto',
            maxBarWidth: 24,
            innerPadding: 0.38,
            isOuterPaddingDefined: false,
            mode: 'plotly',
            hideTickOverlap: true,
            longestLabelWidth: 400,
          );
      final withoutOverlap =
          FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
            categoryCount: 4,
            legendCount: 2,
            containerWidth: 800,
            margins: margins,
            barWidthProp: 'auto',
            maxBarWidth: 24,
            innerPadding: 0.38,
            isOuterPaddingDefined: false,
            mode: 'plotly',
            hideTickOverlap: false,
            longestLabelWidth: 400,
          );
      expect(
        withOverlap.barWidth,
        // 24 is this test's own maxBarWidth, which caps the band fit.
        24,
        reason:
            'GroupedVerticalBarChart.tsx:756 re-solves the bar width from the '
            'band fit before maxBarWidth caps it',
      );
      expect(
        withOverlap.domainMargin,
        greaterThan(withoutOverlap.domainMargin),
        reason:
            'margin2 is +infinity when hideTickOverlap is set, '
            'GroupedVerticalBarChart.tsx:761-767',
      );
      expect(
        withoutOverlap.domainMargin,
        kMinDomainMargin,
        reason:
            'a 400px longest label makes margin2 negative, and '
            'GroupedVerticalBarChart.tsx:769 floors the added margin at 0',
      );
    });

    test('a non-auto bar width never reaches the plotly branch', () {
      expect(
        FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
          categoryCount: 4,
          legendCount: 2,
          containerWidth: 800,
          margins: margins,
          barWidthProp: 'default',
          maxBarWidth: 24,
          innerPadding: 0.38,
          isOuterPaddingDefined: false,
          mode: 'plotly',
          hideTickOverlap: false,
          longestLabelWidth: 400,
        ).domainMargin,
        greaterThan(kMinDomainMargin),
        reason:
            'GroupedVerticalBarChart.tsx:740 takes the centring arm for every '
            'barWidth that is not auto, so the plotly label-overlap solve is '
            'unreachable there',
      );
    });
  });

  group('GVBC oracle geometry', () {
    // charts-groupedverticalbarchart--grouped-vertical-bar-default: four
    // quarters on the x axis, four legends per group, the default bar width.
    const storyId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-default';
    const categories = <String>[
      'Jan - Mar',
      'Apr - Jun',
      'Jul - Sep',
      'Oct - Dec',
    ];
    // The capture records no legend identity per rect, so these stand in for
    // the four series in the order upstream draws them. Only the order is
    // load-bearing: the local band scale keys on it, not on the text.
    const legends = <String>['s1', 's2', 's3', 's4'];
    const barWidth = 16.0;

    test('the captured bar grid reproduces the ported band maths', () {
      final story = loadOracleStory(storyId);
      final groups = _groupElements(story);
      expect(
        groups.length,
        categories.length,
        reason: '$storyId must capture one <g> per category',
      );

      // The x-axis domain path is `M<x0+crisp>,6V<crisp>H<x1+crisp>V6`
      // (`d3-axis/src/axis.js:80`); the y axis's starts `M-6,` and so cannot
      // match this predicate.
      final domainPath = story.soleElement(
        'path',
        where: (element) =>
            (element.d ?? '').contains('V${story.crispOffset}H'),
      );
      final numbers = svgPathNumbers(domainPath.d!);
      final rangeStart = numbers[0] - story.crispOffset;
      // The path emits x0, 6, crisp, x1, 6 — so index 3 is the far end.
      final rangeEnd = numbers[3] - story.crispOffset;

      final innerPadding =
          FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
            legends.length,
          );
      final x0 = _bandScale(
        domain: categories,
        range: <double>[rangeStart, rangeEnd],
        innerPadding: innerPadding,
        outerPadding: 0,
      );

      // Upstream's centring branch leaves the band range exactly as wide as
      // the groups need — `.tsx:750` cancels the slack — which is what makes
      // the captured range a check on `defaultInnerPadding` too.
      expect(
        rangeEnd - rangeStart,
        closeTo(
          calcRequiredWidth(
            calcRequiredWidth(
              barWidth,
              legends.length,
              FluentGroupedVerticalBarChartGeometry.kX1InnerPadding,
            ),
            categories.length,
            innerPadding,
          ),
          kOracleGeometryTolerance,
        ),
        reason:
            'GroupedVerticalBarChart.tsx:744-750 sizes the x0 range to the '
            'required width exactly',
      );

      for (var i = 0; i < categories.length; i++) {
        final layout = FluentGroupedVerticalBarChartGeometry.layOutGroup(
          category: categories[i],
          presentLegends: legends,
          xScale0: x0,
          barWidth: barWidth,
          isRtl: false,
        );
        expectOracleNumber(
          'group ${categories[i]} translate x',
          story.absoluteTranslate(groups[i]).dx,
          layout.translateX,
        );
        final rects = story
            .byTag('rect')
            .where((element) => element.parent == groups[i].index)
            .toList();
        expect(
          rects.length,
          legends.length,
          reason: 'group ${categories[i]} must capture one rect per legend',
        );
        for (var j = 0; j < legends.length; j++) {
          expectOracleNumber(
            'bar x for ${categories[i]}/${legends[j]}',
            rects[j].x!,
            layout.barXByLegend[legends[j]]!,
          );
          expectOracleNumber(
            'bar width for ${categories[i]}/${legends[j]}',
            rects[j].width!,
            barWidth,
          );
        }
      }
    });

    test('the bar label sits 6 above a positive bar and 12 below a negative '
        'one', () {
      final positive = loadOracleStory(storyId);
      final positiveGroups = _groupElements(positive);
      expect(
        positiveGroups,
        isNotEmpty,
        reason: '$storyId must capture at least one group',
      );
      final bar = positive
          .byTag('rect')
          .firstWhere(
            (element) => element.parent == positiveGroups.first.index,
          );
      final label = positive
          .byTag('text')
          .firstWhere(
            (element) => element.parent == positiveGroups.first.index,
          );
      expectOracleNumber(
        'positive bar label baseline',
        label.y!,
        bar.y! - kGvbcGapAbove,
      );

      const negativeId =
          'charts-groupedverticalbarchart--grouped-vertical-bar-negative';
      final negative = loadOracleStory(negativeId);
      final negativeGroups = _groupElements(negative);
      expect(
        negativeGroups,
        isNotEmpty,
        reason: '$negativeId must capture at least one group',
      );
      final negativeRects = negative
          .byTag('rect')
          .where((element) => element.parent == negativeGroups.first.index)
          .toList();
      final negativeTexts = negative
          .byTag('text')
          .where((element) => element.parent == negativeGroups.first.index)
          .toList();
      expect(
        negativeRects.length,
        negativeTexts.length,
        reason: '$negativeId pairs one label with every bar',
      );
      // U+2212 MINUS SIGN, which `formatScientificLimitWidth` emits.
      final below = negativeTexts.indexWhere(
        (element) => element.text!.startsWith('−'),
      );
      expect(
        below,
        isNonNegative,
        reason: '$negativeId must contain a negative bar label',
      );
      expectOracleNumber(
        'negative bar label baseline',
        negativeTexts[below].y!,
        negativeRects[below].y! + negativeRects[below].height! + kGvbcGapBelow,
      );
    });
  });
}
