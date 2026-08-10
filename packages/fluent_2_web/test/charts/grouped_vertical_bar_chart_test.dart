import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/grouped_vertical_bar_chart.dart';
import 'package:fluent_2_web/src/charts/grouped_vertical_bar_chart_style.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_band.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:flutter/widgets.dart';
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

final _theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
final _style = resolveFluentGroupedVerticalBarChartStyle(_theme);
final _textStyles = FluentChartTextStyles.of(_theme);
final _measurer = FluentChartTextMeasurer();

/// An arbitrary colour for every slot a bar delegate never reads.
const _placeholder = Color(0xFF010203);

/// The flattened system colour under forced colours (`FluentChartColors.of`
/// resolves it from the theme; the tests below need to recognise it).
const _canvasText = Color(0xFFFFFFFF);

FluentChartColors _colours({bool isHighContrast = false}) => FluentChartColors(
  axisText: _canvasText,
  axisTick: _placeholder,
  axisTitle: _placeholder,
  gridLine: _placeholder,
  markStroke: _placeholder,
  surface: _placeholder,
  popoverSurface: _placeholder,
  tooltipSurface: _placeholder,
  legendDimmed: _placeholder,
  isHighContrast: isHighContrast,
);

/// The colour walk of `GroupedVerticalBarChart.tsx:298-352`, which the widget
/// owns: the counter advances once per **point**, and a legend keeps the colour
/// it was first handed.
Map<String, Color> _walkLegendColours(
  List<FluentGroupedVerticalBarChartData> data,
) {
  final colours = <String, Color>{};
  var index = 0;
  for (final category in data) {
    for (final point in category.series) {
      colours.putIfAbsent(
        point.legend,
        () => point.color ?? FluentDataVizPalette.next(index),
      );
      index++;
    }
  }
  return colours;
}

FluentGroupedVerticalBarChartDelegate _delegateFor(
  List<FluentGroupedVerticalBarChartData> data, {
  Object? barWidthProp,
  bool isHighContrast = false,
  bool hideLabels = false,
  bool roundCorners = false,
  List<String> selectedLegends = const <String>[],
  String? activeLegend,
}) => FluentGroupedVerticalBarChartDelegate(
  data: data,
  style: _style,
  colors: _colours(isHighContrast: isHighContrast),
  measurer: _measurer,
  textStyles: _textStyles,
  selectedLegends: selectedLegends,
  legendColours: _walkLegendColours(data),
  activeLegend: activeLegend,
  barWidthProp: barWidthProp,
  hideLabels: hideLabels,
  roundCorners: roundCorners,
);

/// One category, one legend per entry of [values], so every bar starts from the
/// baseline rather than stacking.
FluentGroupedVerticalBarChartDelegate _gvbcDelegate({
  required List<double> values,
  Object? barWidth,
  bool isHighContrast = false,
  bool hideLabels = false,
  bool roundCorners = false,
  List<String> selectedLegends = const <String>[],
  List<bool>? useSecondaryYScale,
  List<String?>? barLabels,
}) => _delegateFor(
  <FluentGroupedVerticalBarChartData>[
    FluentGroupedVerticalBarChartData(
      name: 'Category',
      series: <FluentGroupedBarSeriesPoint>[
        for (var i = 0; i < values.length; i++)
          FluentGroupedBarSeriesPoint(
            key: 'L$i',
            data: values[i],
            legend: 'L$i',
            useSecondaryYScale: useSecondaryYScale?[i] ?? false,
            barLabel: barLabels?[i],
          ),
      ],
    ),
  ],
  barWidthProp: barWidth,
  isHighContrast: isHighContrast,
  hideLabels: hideLabels,
  roundCorners: roundCorners,
  selectedLegends: selectedLegends,
);

/// One category, one legend, [values] repeated on it — the stacked-inside-a-
/// group shape only this chart has.
FluentGroupedVerticalBarChartDelegate _gvbcStackedDelegate({
  required List<double> values,
}) => _delegateFor(<FluentGroupedVerticalBarChartData>[
  FluentGroupedVerticalBarChartData(
    name: 'Category',
    series: <FluentGroupedBarSeriesPoint>[
      for (final value in values)
        FluentGroupedBarSeriesPoint(key: 'L', data: value, legend: 'L'),
    ],
  ),
]);

/// Three legends over four categories — twelve points, so the colour counter
/// ends at 12 while the three legends keep entries 0, 1 and 2.
FluentGroupedVerticalBarChartDelegate _gvbcThreeByFour() => _delegateFor(
  <FluentGroupedVerticalBarChartData>[
    for (var category = 0; category < 4; category++)
      FluentGroupedVerticalBarChartData(
        name: 'Category $category',
        series: <FluentGroupedBarSeriesPoint>[
          for (final legend in <String>['A', 'B', 'C'])
            FluentGroupedBarSeriesPoint(key: legend, data: 10, legend: legend),
        ],
      ),
  ],
);

/// A y scale that carries negative values, ranged the way a position scale is:
/// the domain floor at the foot of the plot.
d3.Scale _linearY({
  List<double> domain = const <double>[-50, 100],
  List<double> range = const <double>[307, 28],
}) => d3.scaleLinear()
  ..domainOf(domain)
  ..rangeOf(range);

FluentCartesianChildContext _gvbcContext({
  List<String> categories = const <String>['Category'],
  d3.Scale? yScaleSecondary,
}) => FluentCartesianChildContext(
  xScale: _bandScale(
    domain: categories,
    range: <double>[48, 780],
    // A single category makes the inner padding inert; the multi-category
    // assertions build their own scale from the captured domain path.
    innerPadding: 0,
    outerPadding: 0,
  ),
  yScalePrimary: _linearY(),
  yScaleSecondary: yScaleSecondary,
  containerWidth: 800,
  containerHeight: 350,
);

FluentCartesianLayout _layout({double height = 350, double width = 800}) =>
    FluentCartesianLayout.resolve(
      size: Size(width, height),
      margins: const FluentChartMargins(
        left: 40,
        right: 20,
        top: 28,
        bottom: 43,
      ),
      xAxisLabelReserve: 0,
      isRtl: false,
      startFromX: 0,
    );

/// Records what `paintSeries` draws. `noSuchMethod` swallows the rest, so a
/// painter that starts clipping or saving layers is not silently accepted —
/// those calls simply do not land in these lists.
class _RecordingCanvas implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<RRect> rrects = <RRect>[];
  final List<Color> fills = <Color>[];
  final List<Offset> paragraphs = <Offset>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    fills.add(paint.color);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add(rrect);
    rects.add(rrect.outerRect);
    fills.add(paint.color);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      paragraphs.add(offset);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('GVBC bars', () {
    test('the y scale is the shell position scale, so 0 is the baseline', () {
      final delegate = _gvbcDelegate(values: <double>[-30, 0, 5, 100]);
      final context = _gvbcContext();
      final rects = delegate
          .barsFor(context, _layout(height: 350))
          .map((bar) => bar.rect)
          .toList();
      final baseline = context.yScalePrimary(0)!;
      expect(
        rects.first.top,
        closeTo(baseline, 1e-9),
        reason:
            'yNegativeStart starts at yBarScale(Y_ORIGIN), so a negative bar '
            'hangs off the baseline — GroupedVerticalBarChart.tsx:556-560, '
            ':570-573',
      );
      expect(
        rects[1].bottom,
        closeTo(baseline, 1e-9),
        reason:
            'yPositiveStart starts at the same baseline and a positive bar '
            'grows up from it, GroupedVerticalBarChart.tsx:556-559, :568-570',
      );
    });

    test('a zero value renders nothing at all', () {
      final delegate = _gvbcDelegate(values: <double>[0, 5]);
      expect(
        delegate.barsFor(_gvbcContext(), _layout(height: 350)).length,
        1,
        reason:
            'parity: `if (!pointData.data) return` at '
            'GroupedVerticalBarChart.tsx:562 drops 0, NaN and null alike',
      );
    });

    test('bars are at least one pixel tall', () {
      final delegate = _gvbcDelegate(values: <double>[0.001]);
      expect(
        delegate
            .barsFor(_gvbcContext(), _layout(height: 350))
            .single
            .rect
            .height,
        FluentGroupedVerticalBarChartGeometry.kMinBarHeight,
        reason: 'MIN_BAR_HEIGHT 1, GroupedVerticalBarChart.tsx:567',
      );
    });

    test('a stacked legend column adds a 1px gap after the first bar', () {
      final delegate = _gvbcStackedDelegate(values: <double>[20, 30]);
      final rects = delegate
          .barsFor(_gvbcContext(), _layout(height: 350))
          .map((bar) => bar.rect)
          .toList();
      expect(
        rects[0].top - rects[1].bottom,
        closeTo(FluentGroupedVerticalBarChartGeometry.kVerticalBarGap, 1e-9),
        reason:
            'barGap = (VERTICAL_BAR_GAP / 2) * 2 == 1 for every point after '
            'the first, GroupedVerticalBarChart.tsx:566',
      );
    });

    test('the colour walk advances per POINT, not per legend', () {
      final delegate = _gvbcThreeByFour();
      expect(
        delegate.legendColour('C').toARGB32(),
        FluentDataVizPalette.next(2).toARGB32(),
        reason:
            'the legend colours come from the first category, but the counter '
            'ends at 12 for 3 legends x 4 categories — '
            'GroupedVerticalBarChart.tsx:298-352',
      );
    });

    test('the label width test uses ceil, unlike VBC', () {
      // 15.2 is a width VerticalBarChart's `_barWidth < 16` would reject.
      final delegate = _gvbcDelegate(values: <double>[5], barWidth: 15.2);
      expect(
        delegate.shouldPaintTotalLabel(15.2),
        isTrue,
        reason:
            'parity: `Math.ceil(_barWidth) >= 16` at '
            'GroupedVerticalBarChart.tsx:620 shows a label on a 15.2px bar '
            'where VerticalBarChart would not',
      );
      expect(
        _gvbcDelegate(
          values: <double>[5],
          hideLabels: true,
        ).shouldPaintTotalLabel(24),
        isFalse,
        reason: '`!props.hideLabels` is the first term of the same gate',
      );
    });

    test('a bar dimmed by another legend takes the 0.1 opacity', () {
      final bars = _gvbcDelegate(
        values: <double>[5, 7],
        selectedLegends: <String>['L0'],
      ).barsFor(_gvbcContext(), _layout(height: 350));
      expect(
        bars.map((bar) => bar.opacity).toList(),
        <double>[
          1,
          _style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!,
        ],
        reason:
            "`isLegendActive ? '' : '0.1'`, "
            'GroupedVerticalBarChart.tsx:552-553',
      );
    });

    test('a secondary-scale bar is measured against the secondary scale', () {
      final secondary = _linearY(domain: <double>[0, 1000]);
      final context = _gvbcContext(yScaleSecondary: secondary);
      final bars = _gvbcDelegate(
        values: <double>[500],
        useSecondaryYScale: <bool>[true],
      ).barsFor(context, _layout(height: 350));
      expect(
        bars.single.rect.bottom,
        closeTo(secondary(0)!, 1e-9),
        reason:
            '`barPoints[0].useSecondaryYScale && yScaleSecondary` picks the '
            'scale for the whole column, GroupedVerticalBarChart.tsx:548',
      );
      expect(
        bars.single.rect.height,
        closeTo(secondary(0)! - secondary(500)!, 1e-9),
        reason: 'the height is measured on the same scale, :567',
      );
    });

    test('high contrast flattens the bar fill to the system colour', () {
      expect(
        _gvbcDelegate(values: <double>[5], isHighContrast: true)
            .barsFor(_gvbcContext(), _layout(height: 350))
            .single
            .colour
            .toARGB32(),
        _canvasText.toARGB32(),
        reason:
            'spec section 5.3 — every mark fill routes through '
            'FluentChartColors.flattenMark',
      );
      expect(
        _gvbcDelegate(values: <double>[5])
            .barsFor(_gvbcContext(), _layout(height: 350))
            .single
            .colour
            .toARGB32(),
        FluentDataVizPalette.next(0).toARGB32(),
        reason: 'and keeps the palette colour when contrast is not forced',
      );
    });
  });

  group('GVBC paint and hit regions', () {
    test('every bar is drawn once, with the dim folded into the fill', () {
      final canvas = _RecordingCanvas();
      final delegate = _gvbcDelegate(
        values: <double>[5, 7],
        selectedLegends: <String>['L0'],
      );
      final context = _gvbcContext();
      delegate.paintSeries(canvas, context, _layout(), _colours());
      expect(
        canvas.rects,
        delegate.barsFor(context, _layout()).map((bar) => bar.rect).toList(),
        reason: 'one rect per resolved bar, GroupedVerticalBarChart.tsx:579',
      );
      expect(
        canvas.fills.first.a,
        1,
        reason: 'the selected legend keeps its opaque fill',
      );
      expect(
        canvas.fills.last.a,
        // 255 is the 8-bit alpha channel a Color quantises to.
        closeTo(0.1, 1 / 255),
        reason:
            'the dimmed bar carries the 0.1 of '
            'GroupedVerticalBarChart.tsx:553 in its alpha, because a canvas '
            'has no opacity attribute',
      );
      expect(
        canvas.paragraphs.length,
        1,
        reason:
            'a 16px bar clears the ceil gate, but `isLegendActive` is the '
            'last term of the same gate, so the dimmed column loses its '
            'total label — GroupedVerticalBarChart.tsx:620-637',
      );
    });

    test('roundCorners draws a 3px rounded rect instead', () {
      final canvas = _RecordingCanvas();
      _gvbcDelegate(
        values: <double>[5],
        roundCorners: true,
      ).paintSeries(canvas, _gvbcContext(), _layout(), _colours());
      expect(
        canvas.rrects.single.tlRadiusX,
        _style.barCornerRadius!.resolve(const <WidgetState>{}),
        reason:
            '`rx={props.roundCorners ? 3 : 0}`, '
            'GroupedVerticalBarChart.tsx:588',
      );
    });

    test('a per-point label is drawn above its own bar', () {
      final canvas = _RecordingCanvas();
      final delegate = _gvbcDelegate(
        values: <double>[5],
        barLabels: <String?>['five'],
        hideLabels: true,
      );
      final context = _gvbcContext();
      delegate.paintSeries(canvas, context, _layout(), _colours());
      final bar = delegate.barsFor(context, _layout()).single;
      expect(
        canvas.paragraphs.length,
        1,
        reason:
            'hideLabels suppresses the total label but never the per-point '
            'one, GroupedVerticalBarChart.tsx:602 vs :620',
      );
      expect(
        canvas.paragraphs.single.dy,
        lessThan(bar.rect.top - kGvbcGapAbove),
        reason:
            'the label baseline sits 6 above a positive bar, so its painted '
            'top is higher still by the ascent — '
            'GroupedVerticalBarChart.tsx:607',
      );
    });

    test('a dimmed bar is not an interactive region', () {
      final delegate = _gvbcDelegate(
        values: <double>[5, 7],
        selectedLegends: <String>['L0'],
      );
      final regions = delegate.buildHitRegions(_gvbcContext(), _layout());
      expect(
        regions.map((region) => region.legend).toList(),
        <String>['L0'],
        reason:
            'a bar dimmed by another legend gets no tab index at '
            'GroupedVerticalBarChart.tsx:596',
      );
      expect(
        regions.single.semanticsLabel,
        'Category. L0, 5.',
        reason:
            '`${r'$'}{xValue}. ${r'$'}{legend}, ${r'$'}{yValue}.`, '
            'GroupedVerticalBarChart.tsx:728',
      );
    });
  });

  group('GVBC oracle bars', () {
    // The same story the band-scale assertions above read, now driven through
    // the delegate: the values are the captured bar labels, which the captured
    // heights confirm exactly against the 60k y domain.
    const storyId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-default';
    const categories = <String>[
      'Jan - Mar',
      'Apr - Jun',
      'Jul - Sep',
      'Oct - Dec',
    ];
    const values = <List<double>>[
      <double>[33000, 44000, 54000, 24000],
      <double>[33000, 3000, 9000, 12000],
      <double>[14000, 50000, 60000, 10000],
      <double>[33000, 3000, 6000, 15000],
    ];
    const legends = <String>['s1', 's2', 's3', 's4'];

    /// The y a captured axis tick sits at, with the crispness offset removed.
    double yOfTick(OracleStory story, String label) {
      final text = story.soleElement(
        'text',
        // -10 is the captured y-tick label offset; it separates the axis
        // labels from the bar labels, which carry the same strings.
        where: (element) => element.text == label && element.x == -10,
      );
      return story.absoluteTranslate(story.parentOf(text)!).dy -
          story.crispOffset;
    }

    test('every captured bar rect comes back out of barsFor', () {
      final story = loadOracleStory(storyId);
      final groups = _groupElements(story);
      expect(
        groups.length,
        categories.length,
        reason: '$storyId must capture one <g> per category',
      );

      final domainPath = story.soleElement(
        'path',
        where: (element) =>
            (element.d ?? '').contains('V${story.crispOffset}H'),
      );
      final numbers = svgPathNumbers(domainPath.d!);
      final xScale = _bandScale(
        domain: categories,
        // The path emits x0, 6, crisp, x1, 6.
        range: <double>[
          numbers[0] - story.crispOffset,
          numbers[3] - story.crispOffset,
        ],
        innerPadding: FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
          legends.length,
        ),
        outerPadding: 0,
      );
      final delegate = _delegateFor(<FluentGroupedVerticalBarChartData>[
        for (var category = 0; category < categories.length; category++)
          FluentGroupedVerticalBarChartData(
            name: categories[category],
            series: <FluentGroupedBarSeriesPoint>[
              for (var legend = 0; legend < legends.length; legend++)
                FluentGroupedBarSeriesPoint(
                  key: legends[legend],
                  data: values[category][legend],
                  legend: legends[legend],
                ),
            ],
          ),
      ]);
      final bars = delegate.barsFor(
        FluentCartesianChildContext(
          xScale: xScale,
          yScalePrimary: d3.scaleLinear()
            // 0 and 60000 are the first and last captured y ticks.
            ..domainOf(<double>[0, 60000])
            ..rangeOf(<double>[yOfTick(story, '0'), yOfTick(story, '60k')]),
          containerWidth: story.width,
          containerHeight: story.height,
        ),
        _layout(),
      );
      expect(
        bars.length,
        categories.length * legends.length,
        reason: '$storyId captures sixteen bars',
      );

      for (var category = 0; category < categories.length; category++) {
        final translate = story.absoluteTranslate(groups[category]);
        final rects = story
            .byTag('rect')
            .where((element) => element.parent == groups[category].index)
            .toList();
        expect(
          rects.length,
          legends.length,
          reason:
              'group ${categories[category]} must capture one rect per '
              'legend',
        );
        for (var legend = 0; legend < legends.length; legend++) {
          expectOracleRect(
            'bar ${categories[category]}/${legends[legend]}',
            rects[legend].rect.translate(translate.dx, translate.dy),
            bars[category * legends.length + legend].rect,
          );
        }
      }
    });
  });
}
