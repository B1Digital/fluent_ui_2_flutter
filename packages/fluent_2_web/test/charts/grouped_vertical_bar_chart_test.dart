import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
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
  double? xAxisOuterPadding,
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
  xAxisOuterPadding: xAxisOuterPadding,
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

/// One category carrying one legend — the v1 input the widget tests hover.
List<FluentGroupedVerticalBarChartData> _gvbcCategories() =>
    const <FluentGroupedVerticalBarChartData>[
      FluentGroupedVerticalBarChartData(
        name: 'Category',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(key: 'L', data: 100, legend: 'L'),
        ],
      ),
    ];

/// Two bar series over one category — the v2 input.
List<FluentDataSeries> _gvbcV2Series() => const <FluentDataSeries>[
  FluentBarSeries(
    legend: 'v2a',
    data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 10)],
  ),
  FluentBarSeries(
    legend: 'v2b',
    data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 20)],
  ),
];

/// The same two bar series with a line over the top — the only input shape
/// that can carry one (`GroupedVerticalBarChart.tsx:290-291`).
List<FluentDataSeries> _gvbcV2WithLine() => <FluentDataSeries>[
  ..._gvbcV2Series(),
  const FluentLineSeries(
    legend: 'Trend',
    data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 15)],
  ),
];

/// The y a captured axis tick sits at, with the crispness offset removed.
double _yOfTick(OracleStory story, String label) {
  final text = story.soleElement(
    'text',
    // -10 is the captured y-tick label offset; it separates the axis labels
    // from the bar labels, which carry the same strings.
    where: (element) => element.text == label && element.x == -10,
  );
  return story.absoluteTranslate(story.parentOf(text)!).dy - story.crispOffset;
}

/// Records what `paintSeries` draws. `noSuchMethod` swallows the rest, so a
/// painter that starts clipping or saving layers is not silently accepted —
/// those calls simply do not land in these lists.
class _RecordingCanvas implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<RRect> rrects = <RRect>[];
  final List<Color> fills = <Color>[];
  final List<Offset> paragraphs = <Offset>[];
  final List<
    ({Offset from, Offset to, Color colour, double width, StrokeCap cap})
  >
  lines =
      <({Offset from, Offset to, Color colour, double width, StrokeCap cap})>[];
  final List<
    ({Offset centre, double radius, Color colour, double width, bool stroked})
  >
  circles =
      <
        ({
          Offset centre,
          double radius,
          Color colour,
          double width,
          bool stroked,
        })
      >[];

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
  void drawLine(Offset from, Offset to, Paint paint) => lines.add((
    from: from,
    to: to,
    colour: paint.color,
    width: paint.strokeWidth,
    cap: paint.strokeCap,
  ));

  @override
  void drawCircle(Offset centre, double radius, Paint paint) => circles.add((
    centre: centre,
    radius: radius,
    colour: paint.color,
    width: paint.strokeWidth,
    stroked: paint.style == PaintingStyle.stroke,
  ));

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

    /// The shell margins the story was captured with.
    ///
    /// Left is read straight off the capture — the y-axis group carries
    /// `translate(40, 0)` — and top and bottom off its domain path
    /// `M-6,275.5H0.5V20.5H-6` against the 310px height. Right then falls out
    /// of the x-axis domain path below: `rangeStart` fixes the domain margin at
    /// `148.3333 - 40`, and `650 - 521.6667 - 108.3333` is 20, which is also
    /// `DEFAULT_MARGIN_NO_TICKS` (`CartesianChart.tsx:676`) for a chart with no
    /// secondary y scale.
    const margins = FluentChartMargins(
      top: 20,
      bottom: 35,
      left: 40,
      right: 20,
    );

    /// The `[rangeStart, rangeEnd]` of [story]'s x axis, read off the domain
    /// path `M<x0+crisp>,6V<crisp>H<x1+crisp>V6` (`d3-axis/src/axis.js:80`).
    (double, double) xRangeOf(OracleStory story) {
      final domainPath = story.soleElement(
        'path',
        where: (element) =>
            (element.d ?? '').contains('V${story.crispOffset}H'),
      );
      final numbers = svgPathNumbers(domainPath.d!);
      // The path emits x0, 6, crisp, x1, 6, so index 3 is the far end.
      return (numbers[0] - story.crispOffset, numbers[3] - story.crispOffset);
    }

    // The gate on `_getDomainMargins` reaching the shell at all
    // (`CartesianChart.tsx:195`). Every other assertion in this group feeds the
    // captured range back in by hand, so all of them pass while
    // `FluentGroupedVerticalBarChartGeometry.solveDomainMargin` has no `lib/`
    // caller — which it had none of for four waves.
    test('the delegate widens the shell margins by the solved margin', () {
      final story = loadOracleStory(storyId);
      final (rangeStart, rangeEnd) = xRangeOf(story);
      final solved = _delegateFor(<FluentGroupedVerticalBarChartData>[
        for (final category in categories)
          FluentGroupedVerticalBarChartData(
            name: category,
            series: <FluentGroupedBarSeriesPoint>[
              for (final legend in legends)
                // Only the legend count reaches the solve; the value does not.
                FluentGroupedBarSeriesPoint(
                  key: '$category/$legend',
                  data: 1,
                  legend: legend,
                ),
            ],
          ),
      ]).domainMargins(story.width, margins);
      expect(
        solved,
        isNotNull,
        reason:
            'CartesianChart.tsx:195 falls back to the plain margins when '
            'getDomainMargins is absent, so a null here is the shell laying '
            'every group out with no domain margin at all',
      );
      expectOracleNumber('gvbc x range start', rangeStart, solved!.left!);
      expectOracleNumber(
        'gvbc x range end',
        rangeEnd,
        story.width - solved.right!,
      );
      expect(
        solved.top,
        margins.top,
        reason:
            'GroupedVerticalBarChart.tsx:774-777 spreads the incoming margins '
            'and replaces only left and right',
      );
      expect(
        solved.bottom,
        margins.bottom,
        reason: 'the same spread at GroupedVerticalBarChart.tsx:774',
      );
    });

    // The delegate must DERIVE `isOuterPaddingDefined` from its own prop.
    // `solveDomainMargin(isOuterPaddingDefined: true)` returning 0 — which the
    // unit group above asserts — is satisfied by a delegate that hard-codes
    // false and ignores the caller entirely.
    test('a defined outer padding leaves the shell margins alone', () {
      final data = <FluentGroupedVerticalBarChartData>[
        for (final category in categories)
          FluentGroupedVerticalBarChartData(
            name: category,
            series: <FluentGroupedBarSeriesPoint>[
              for (final legend in legends)
                FluentGroupedBarSeriesPoint(
                  key: '$category/$legend',
                  data: 1,
                  legend: legend,
                ),
            ],
          ),
      ];
      final withPadding = _delegateFor(
        data,
        xAxisOuterPadding: 0.1,
      ).domainMargins(650, margins);
      expect(
        withPadding!.left,
        margins.left,
        reason:
            'GroupedVerticalBarChart.tsx:736-739 zeroes _domainMargin outright '
            'once xAxisOuterPadding is defined',
      );
      expect(
        withPadding.right,
        margins.right,
        reason: 'the same zero on the other end',
      );
      expect(
        _delegateFor(data).domainMargins(650, margins)!.left,
        greaterThan(margins.left!),
        reason:
            'a control: the same four groups DO widen the margins without the '
            'padding, so the assertion above is about the prop',
      );
    });

    // The solve sizes the band range to `reqWidth` at the resolved paddings
    // (`.tsx:744-750`); the shell then pads the band scale from the delegate's
    // own hooks. If those disagree, the groups no longer fill the range they
    // were centred in — which is what silently narrowed the bars past the
    // `ceil(_barWidth) >= 16` label gate at `.tsx:620`.
    testWidgets('the shell band scale is padded with the resolved values', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            // 260x180 is the golden grid's own cell size, so this pins what
            // the goldens capture.
            child: SizedBox(
              width: 260,
              height: 180,
              // Two groups of two, because four groups of four need 373px of
              // required width and this box has 184 — `.tsx:749` then never
              // fires and there is no centring to check.
              child: FluentGroupedVerticalBarChart(
                data: <FluentGroupedVerticalBarChartData>[
                  for (final category in categories.take(2))
                    FluentGroupedVerticalBarChartData(
                      name: category,
                      series: <FluentGroupedBarSeriesPoint>[
                        for (final legend in legends.take(2))
                          FluentGroupedBarSeriesPoint(
                            key: '$category/$legend',
                            data: 10,
                            legend: legend,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((widget) => widget.painter)
          .whereType<FluentCartesianChartPainter>()
          .first;
      final delegate =
          painter.delegate as FluentGroupedVerticalBarChartDelegate;
      final scale = painter.xAxis.scale;
      expect(
        scale(categories.first),
        closeTo(
          delegate
              .domainMargins(painter.layout.size.width, painter.layout.margins)!
              .left!,
          1e-9,
        ),
        reason:
            '_xAxisOuterPadding is getScalePadding(props.xAxisOuterPadding), 0 '
            'by default (.tsx:137), and .tsx:1015 hands that to the shell. A '
            'null there lets createStringXAxis fall back to its own '
            'xAxisPadding of 0.1 (utilities.ts:574, spent at :586) and inset the '
            'first group.',
      );
      expect(
        delegate.barWidthFor(scale),
        closeTo(kDefaultBarWidth, 1e-9),
        reason:
            'the solve sized the range so the groups exactly fill it at a 16px '
            'bar (.tsx:744-750), so the live bandwidth must give 16 back — the '
            'number the whole centring was computed from',
      );
    });

    // `calculateLongestLabelWidth(_xAxisLabels)` (`.tsx:764`) is read only in
    // the plotly arm and only when overlap hiding is off, and no captured GVBC
    // story sets `mode: 'plotly'`. Asserted relatively, because `flutter test`
    // resolves a different font from the capture browser and a hard-coded
    // width would pin the harness rather than the port.
    test('the plotly margin reads the x labels only when tick overlap is '
        'allowed', () {
      FluentGroupedVerticalBarChartDelegate delegateOver(
        List<String> names, {
        required bool hideTickOverlap,
      }) => FluentGroupedVerticalBarChartDelegate(
        data: <FluentGroupedVerticalBarChartData>[
          for (final name in names)
            FluentGroupedVerticalBarChartData(
              name: name,
              series: <FluentGroupedBarSeriesPoint>[
                for (final legend in legends)
                  FluentGroupedBarSeriesPoint(
                    key: '$name/$legend',
                    data: 1,
                    legend: legend,
                  ),
              ],
            ),
        ],
        style: _style,
        colors: _colours(),
        measurer: _measurer,
        textStyles: _textStyles,
        selectedLegends: const <String>[],
        legendColours: const <String, Color>{},
        // `.tsx:740` claims every barWidth that is not `auto` for the centring
        // arm above, so the plotly arm is unreachable without it.
        barWidthProp: 'auto',
        mode: 'plotly',
        hideTickOverlap: hideTickOverlap,
      );

      const short = <String>['a', 'b', 'c', 'd'];
      final long = <String>[for (final name in short) name * 30];
      expect(
        delegateOver(
          long,
          hideTickOverlap: false,
        ).domainMargins(650, margins)!.left,
        lessThan(
          delegateOver(
            short,
            hideTickOverlap: false,
          ).domainMargins(650, margins)!.left!,
        ),
        reason:
            'margin2 is `(totalWidth - (n - innerPadding) * (longest + 20)) / 2` '
            '(.tsx:764-766) and the min at :769 takes it, so a wider label '
            'leaves less room. A delegate passing 0 makes these two equal.',
      );
      expect(
        delegateOver(
          long,
          hideTickOverlap: true,
        ).domainMargins(650, margins)!.left,
        delegateOver(
          short,
          hideTickOverlap: true,
        ).domainMargins(650, margins)!.left,
        reason:
            'margin2 stays +infinity when overlap hiding is on (.tsx:763), so '
            'the label width drops out of the min entirely — a delegate that '
            'hard-coded hideTickOverlap would not reproduce both halves',
      );
    });

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
            ..rangeOf(<double>[_yOfTick(story, '0'), _yOfTick(story, '60k')]),
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

  group('GVBC line overlay', () {
    // charts-groupedverticalbarchart--grouped-vertical-bar-chart-line: four
    // quarters, four bar legends per group, two line series over the top.
    const storyId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line';
    const categories = <String>[
      'Jan - Mar',
      'Apr - Jun',
      'Jul - Sep',
      'Oct - Dec',
    ];
    // The captured line colours. Every GVBC story sets its colours explicitly
    // — the bars of the default story start at palette entry 2, not 0 — so
    // these are read off the capture rather than walked out of the palette.
    const lineOne = Color(0xFF637CEF);
    const lineTwo = Color(0xFFE3008C);
    // Inverted from the captured dot centres through the captured y scale,
    // whose '0' and '55k' ticks the assertions below rebuild.
    const valuesOne = <double>[-21600, 21812, -21712, 24800];
    const valuesTwo = <double>[29700, -28400, 28200, -29400];
    // GroupedVerticalBarChart.tsx:837 — the captured halo is 7px wide, which
    // is `3 + lineBorderWidth * 2` at a lineBorderWidth of 2.
    const lineBorderWidth = 2.0;

    List<FluentLineSeries> lineSeries({
      double? borderWidth = lineBorderWidth,
    }) => <FluentLineSeries>[
      for (final (legend, colour, values) in <(String, Color, List<double>)>[
        ('Line 1', lineOne, valuesOne),
        ('Line 2', lineTwo, valuesTwo),
      ])
        FluentLineSeries(
          legend: legend,
          color: colour,
          lineOptions: borderWidth == null
              ? null
              : FluentLineOptions(lineBorderWidth: borderWidth),
          data: <FluentDataPointV2>[
            for (var i = 0; i < categories.length; i++)
              FluentDataPointV2(x: categories[i], y: values[i]),
          ],
        ),
    ];

    FluentGroupedVerticalBarChartDelegate delegate({
      double? borderWidth = lineBorderWidth,
      String? activeLinePoint,
      List<String> selectedLegends = const <String>[],
      bool isHighContrast = false,
    }) => FluentGroupedVerticalBarChartDelegate(
      data: const <FluentGroupedVerticalBarChartData>[],
      lineSeries: lineSeries(borderWidth: borderWidth),
      style: _style,
      colors: _colours(isHighContrast: isHighContrast),
      measurer: _measurer,
      textStyles: _textStyles,
      selectedLegends: selectedLegends,
      legendColours: const <String, Color>{
        'Line 1': lineOne,
        'Line 2': lineTwo,
      },
      activeLinePoint: activeLinePoint,
    );

    /// The story's own scales: the x band the four groups sit on and the y
    /// position scale its ticks describe.
    FluentCartesianChildContext contextOf(OracleStory story) {
      final domainPath = story.soleElement(
        'path',
        where: (element) =>
            (element.d ?? '').contains('V${story.crispOffset}H'),
      );
      final numbers = svgPathNumbers(domainPath.d!);
      return FluentCartesianChildContext(
        xScale: _bandScale(
          domain: categories,
          // The path emits x0, 6, crisp, x1, 6.
          range: <double>[
            numbers[0] - story.crispOffset,
            numbers[3] - story.crispOffset,
          ],
          innerPadding:
              FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
                // The four bar legends the capture draws per group; the line
                // dots sit on the band those four define.
                4,
              ),
          outerPadding: 0,
        ),
        yScalePrimary: d3.scaleLinear()
          // 0 and 55000 are the first and last captured y ticks above zero.
          ..domainOf(<double>[0, 55000])
          ..rangeOf(<double>[_yOfTick(story, '0'), _yOfTick(story, '55k')]),
        containerWidth: story.width,
        containerHeight: story.height,
      );
    }

    test('the capture carries four bar legends per group', () {
      final story = loadOracleStory(storyId);
      final groups = _groupElements(story);
      expect(
        groups.length,
        categories.length,
        reason: '$storyId must capture one <g> per category',
      );
      for (final group in groups) {
        expect(
          story
              .byTag('rect')
              .where((element) => element.parent == group.index)
              .length,
          4,
          reason:
              'the inner padding the line dots are centred on is derived from '
              'the bar legend count (GroupedVerticalBarChart.tsx:132-136)',
        );
      }
    });

    test('every captured dot centre comes back out of paintSeries', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate().paintSeries(canvas, contextOf(story), _layout(), _colours());
      final captured = story.byTag('circle').toList();
      expect(
        captured.length,
        categories.length * 2,
        reason: '$storyId captures four dots on each of two lines',
      );
      expect(
        canvas.circles.length,
        captured.length * 2,
        reason:
            'each dot is a fill and a ring, GroupedVerticalBarChart.tsx:871 '
            'and :873',
      );
      for (var i = 0; i < captured.length; i++) {
        expectOracleOffset(
          'dot $i',
          captured[i].centre,
          // Fill then ring, so the fill of dot i is at 2i.
          canvas.circles[i * 2].centre,
        );
      }
    });

    test('every captured line segment comes back out of paintSeries', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate().paintSeries(canvas, contextOf(story), _layout(), _colours());
      // 3 is the captured stroke width of a line, 7 that of its halo.
      final captured = story
          .byTag('line')
          .where((element) => element.strokeWidth == 3)
          .toList();
      expect(
        captured.length,
        (categories.length - 1) * 2,
        reason: '$storyId captures three segments on each of two lines',
      );
      final painted = canvas.lines
          .where((line) => line.width == 3)
          .toList(growable: false);
      expect(
        painted.length,
        captured.length,
        reason: 'one drawLine per captured <line>',
      );
      for (var i = 0; i < captured.length; i++) {
        expectOracleOffset(
          'segment $i start',
          captured[i].start,
          painted[i].from,
        );
        expectOracleOffset('segment $i end', captured[i].end, painted[i].to);
      }
    });

    test(
      'the halo is drawn under every line and 2 * lineBorderWidth wider',
      () {
        final story = loadOracleStory(storyId);
        final canvas = _RecordingCanvas();
        delegate().paintSeries(canvas, contextOf(story), _layout(), _colours());
        final capturedHalo = story
            .byTag('line')
            .where((element) => element.strokeWidth > 3)
            .toList();
        expect(
          capturedHalo.length,
          (categories.length - 1) * 2,
          reason: '$storyId captures one halo per segment',
        );
        expect(
          capturedHalo.first.strokeWidth,
          3 + lineBorderWidth * 2,
          reason:
              'GroupedVerticalBarChart.tsx:837 hard-codes the 3 rather than '
              'reading lineOptions.strokeWidth',
        );
        expect(
          canvas.lines
              .take(capturedHalo.length)
              .every((line) => line.width == 7),
          isTrue,
          reason:
              'every halo is painted before any line, as the two <g> groups at '
              'GroupedVerticalBarChart.tsx:909-911 are ordered',
        );
        expect(
          canvas.lines.first.colour,
          capturedHalo.first.stroke,
          reason:
              'the halo is colorNeutralBackground1 when lineOptions names no '
              'lineBorderColor, GroupedVerticalBarChart.tsx:836',
        );
        expect(
          canvas.lines.first.cap,
          StrokeCap.round,
          reason: 'strokeLinecap="round", GroupedVerticalBarChart.tsx:838',
        );
      },
    );

    test('a line with no lineBorderWidth paints no halo', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate(
        borderWidth: null,
      ).paintSeries(canvas, contextOf(story), _layout(), _colours());
      expect(
        canvas.lines.map((line) => line.width).toSet(),
        <double>{3},
        reason:
            'the halo is gated on `lineBorderWidth > 0`, '
            'GroupedVerticalBarChart.tsx:827',
      );
    });

    test('the idle dot is drawn sub-pixel and the active one at 8', () {
      final story = loadOracleStory(storyId);
      final captured = story.byTag('circle').toList();
      expect(
        captured.first.r,
        0.3,
        reason:
            'the idle radius at GroupedVerticalBarChart.tsx:870 is 0.3, not 0',
      );
      expect(
        captured.first.strokeWidth,
        3,
        reason: 'GroupedVerticalBarChart.tsx:873',
      );
      final canvas = _RecordingCanvas();
      delegate(
        // Series 0, point 1 — the dot id `_getDotId` builds at `.tsx:987`.
        activeLinePoint: '0-1',
      ).paintSeries(canvas, contextOf(story), _layout(), _colours());
      expect(
        canvas.circles.map((circle) => circle.radius).toList(),
        <double>[
          0.3,
          0.3,
          8,
          8,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
          0.3,
        ],
        reason:
            'only the dot whose id is active grows, '
            'GroupedVerticalBarChart.tsx:870',
      );
      expect(
        // Fill then ring, so the ring of the grown dot is at index 3.
        canvas.circles[3].width,
        3,
        reason:
            'the ring keeps its 3px stroke, '
            'GroupedVerticalBarChart.tsx:873',
      );
    });

    test('an active category grows the dot of every line', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate(
        activeLinePoint: categories[1],
      ).paintSeries(canvas, contextOf(story), _layout(), _colours());
      expect(
        canvas.circles.where((circle) => circle.radius == 8).length,
        4,
        reason:
            '`activeLinePoint === point.x` is the isCalloutForStack arm of '
            'GroupedVerticalBarChart.tsx:863, and it matches on both lines',
      );
    });

    test('a line dimmed by another legend drops to 0.1', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate(
        selectedLegends: <String>['Line 2'],
      ).paintSeries(canvas, contextOf(story), _layout(), _colours());
      expect(
        canvas.lines.first.colour.a,
        // 1e-6 absorbs the 8-bit round trip a Paint colour makes.
        closeTo(0.1, 1e-6),
        reason:
            '`opacity={shouldHighlight ? 1 : 0.1}`, '
            'GroupedVerticalBarChart.tsx:839',
      );
      expect(
        canvas.lines.last.colour.a,
        1,
        reason: 'the selected line keeps full opacity',
      );
    });

    test('high contrast flattens the line and its halo apart', () {
      final story = loadOracleStory(storyId);
      final canvas = _RecordingCanvas();
      delegate(isHighContrast: true).paintSeries(
        canvas,
        contextOf(story),
        _layout(),
        _colours(isHighContrast: true),
      );
      final line = canvas.lines.firstWhere((line) => line.width == 3);
      expect(
        line.colour.toARGB32(),
        _canvasText.toARGB32(),
        reason:
            'a line is a series mark, so flattenMark sends it to the system '
            'foreground — design spec section 5.3',
      );
      expect(
        canvas.lines.first.colour.toARGB32(),
        _placeholder.toARGB32(),
        reason:
            'the halo behind it is what keeps the line off the marks under it, '
            'so it takes FluentChartColors.flattenMarkStroke and lands on the '
            'canvas colour',
      );
      expect(
        canvas.circles[1].colour.toARGB32(),
        _placeholder.toARGB32(),
        reason:
            'and so does the dot ring, which is the marker halo — '
            'flattenMarkStroke, not flattenMark',
      );
    });

    test('a dot is a hit region carrying the line point', () {
      final story = loadOracleStory(storyId);
      final regions = delegate().buildHitRegions(contextOf(story), _layout());
      expect(
        regions.length,
        categories.length * 2,
        reason:
            'one region per dot, `tabIndex={shouldHighlight ? 0 : ...}` at '
            'GroupedVerticalBarChart.tsx:877',
      );
      expect(
        regions.first.legend,
        'Line 1',
        reason: 'the region names the line series',
      );
      expect(
        regions.first.popoverData.xValue,
        categories.first,
        reason:
            'XValue = xAxisCalloutData ?? groupData.xAxisPoint, '
            'GroupedVerticalBarChart.tsx:975',
      );
      expect(
        regions.first.semanticsLabel,
        // The reading is the chart's own scientific format, as the bar regions
        // above it are; U+2212 is the minus that formatter emits.
        '${categories.first}. Line 1, \u221221.6k.',
        reason: 'getAriaLabel, GroupedVerticalBarChart.tsx:724-729',
      );
      expect(
        regions.first.bounds.width,
        16,
        reason:
            'the target is the 8px active dot, GroupedVerticalBarChart.tsx:870',
      );
    });

    test('a dimmed line is not an interactive region', () {
      final story = loadOracleStory(storyId);
      final regions = delegate(
        selectedLegends: <String>['Line 2'],
      ).buildHitRegions(contextOf(story), _layout());
      expect(
        regions.map((region) => region.legend).toSet(),
        <String>{'Line 2'},
        reason:
            'a dimmed dot gets no tab index at '
            'GroupedVerticalBarChart.tsx:877',
      );
    });
  });

  group('FluentGroupedVerticalBarChart', () {
    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 800, height: 350, child: chart)),
      ),
    );

    testWidgets('dataV2 replaces data when non-empty', (tester) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(
          data: _gvbcCategories(),
          dataV2: _gvbcV2Series(),
        ),
      );
      final d =
          tester
                  .widget<FluentCartesianChart>(
                    find.byType(FluentCartesianChart),
                  )
                  .delegate
              as FluentGroupedVerticalBarChartDelegate;
      expect(
        d.barLegends,
        <String>['v2a', 'v2b'],
        reason:
            'GroupedVerticalBarChart.tsx:296-304 — dataV2 wins only when it is '
            'a non-empty array',
      );
    });

    testWidgets('an empty dataV2 leaves data in place', (tester) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(
          data: _gvbcCategories(),
          dataV2: const <FluentDataSeries>[],
        ),
      );
      final d =
          tester
                  .widget<FluentCartesianChart>(
                    find.byType(FluentCartesianChart),
                  )
                  .delegate
              as FluentGroupedVerticalBarChartDelegate;
      expect(
        d.barLegends,
        <String>['L'],
        reason:
            '`Array.isArray(props.dataV2) && props.dataV2.length > 0`, '
            'GroupedVerticalBarChart.tsx:302',
      );
    });

    testWidgets('line legends lead the legend row', (tester) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(dataV2: _gvbcV2WithLine()),
      );
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.first.title,
        'Trend',
        reason:
            'GroupedVerticalBarChart.tsx:252-253 adds line legends first, the '
            'reverse of VerticalStackedBarChart',
      );
      expect(
        legends.map((legend) => legend.title).toList(),
        <String>['Trend', 'v2a', 'v2b'],
        reason: 'and the bar legends follow in first-appearance order',
      );
    });

    testWidgets('the colour walk counts every point, then the lines', (
      tester,
    ) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(dataV2: _gvbcV2WithLine()),
      );
      final legends = tester
          .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
          .legends;
      expect(
        legends.map((legend) => legend.color).toList(),
        <Color>[
          // Two bar points advance the counter to 2 before the line series is
          // reached (GroupedVerticalBarChart.tsx:298-352).
          FluentDataVizPalette.next(2),
          FluentDataVizPalette.next(0),
          FluentDataVizPalette.next(1),
        ],
        reason:
            'the counter advances per bar point and the lines are coloured '
            'after every bar, GroupedVerticalBarChart.tsx:322 and :344',
      );
    });

    testWidgets('the nearest-dot tie-break keeps the current point', (
      tester,
    ) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(dataV2: _gvbcV2WithLine()),
      );
      final state = tester.state<FluentGroupedVerticalBarChartState>(
        find.byType(FluentGroupedVerticalBarChart),
      );
      expect(
        state.nearestLinePointIndex(<double>[200, 300], 1, 250),
        1,
        reason:
            'the comparison is strict < at GroupedVerticalBarChart.tsx:930, so '
            'an exact midpoint keeps the current index',
      );
      expect(
        state.nearestLinePointIndex(<double>[200, 300], 1, 249.9),
        0,
        reason: 'just under the midpoint flips to the previous point',
      );
      expect(
        state.nearestLinePointIndex(<double>[200, 300], 0, 299),
        0,
        reason: 'the first point has no predecessor to flip to, `.tsx:928`',
      );
    });

    testWidgets('the popover anchors to the bar, not the pointer', (
      tester,
    ) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(
          data: _gvbcCategories(),
          // 200 is a test constant: the pointer assertions hover the chart's
          // own centre, and a 24px bar would need the plot centre solved here
          // to be hit at all.
          barWidth: 200.0,
          maxBarWidth: 300,
        ),
      );
      final g = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      final centre = tester.getCenter(find.byType(FluentCartesianChart));
      await g.moveTo(centre);
      await tester.pumpAndSettle();
      final first = tester
          .widget<FluentChartPopover>(find.byType(FluentChartPopover))
          .anchor;
      await g.moveTo(centre + const Offset(40, 20));
      await tester.pumpAndSettle();
      final second = tester
          .widget<FluentChartPopover>(find.byType(FluentChartPopover))
          .anchor;
      expect(
        second,
        first,
        reason:
            'GVBC alone sets popoverTarget to the element, not a virtual '
            'element at the pointer (GroupedVerticalBarChart.tsx:437, :970), '
            'so moving inside one bar cannot move the popover',
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .popoverAnchorsToRegion,
        isTrue,
        reason: 'and the anchor is the hovered bar, not the pointer',
      );
    });

    testWidgets('the semantic title counts bar and line series', (
      tester,
    ) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(
          dataV2: _gvbcV2WithLine(),
          chartTitle: 'Usage',
        ),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Usage. Vertical bar chart with 2 grouped bar series and 1 line '
        'series. ',
        reason: 'GroupedVerticalBarChart.tsx:789-795',
      );
    });

    testWidgets('a chart with no lines ends the sentence at the bar count', (
      tester,
    ) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(data: _gvbcCategories()),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Vertical bar chart with 1 grouped bar series. ',
        reason:
            'the line arm of GroupedVerticalBarChart.tsx:793 is a plain `. `',
      );
    });

    testWidgets('an empty chart narrates instead of painting', (tester) async {
      await pump(tester, const FluentGroupedVerticalBarChart());
      expect(
        find.byType(FluentCartesianChart),
        findsNothing,
        reason: '`_isChartEmpty`, GroupedVerticalBarChart.tsx:780-787',
      );
      expect(
        find.bySemanticsLabel('Graph has no data to display'),
        findsOneWidget,
        reason: 'the alert div at GroupedVerticalBarChart.tsx:1031',
      );
    });

    testWidgets('a line with data alone is not an empty chart', (tester) async {
      await pump(
        tester,
        const FluentGroupedVerticalBarChart(
          dataV2: <FluentDataSeries>[
            FluentLineSeries(
              legend: 'Trend',
              data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 15)],
            ),
          ],
        ),
      );
      expect(
        find.byType(FluentCartesianChart),
        findsOneWidget,
        reason:
            '`_lineData.some(series => series.data.length > 0)`, '
            'GroupedVerticalBarChart.tsx:785',
      );
    });

    testWidgets('hovering a line dot enlarges it and opens its popover', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentGroupedVerticalBarChart(
          // One bar legend, so the group is one bar wide and its centre is the
          // band centre the dot sits on; 200 is the same test constant the
          // popover assertions use, so the first hover cannot miss it.
          dataV2: <FluentDataSeries>[
            FluentBarSeries(
              legend: 'v2a',
              data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 10)],
            ),
            FluentLineSeries(
              legend: 'Trend',
              data: <FluentDataPointV2>[FluentDataPointV2(x: 'Q1', y: 15)],
            ),
          ],
          barWidth: 200.0,
          maxBarWidth: 300,
        ),
      );
      final chart = find.byType(FluentCartesianChart);
      final g = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
      await g.addPointer(location: Offset.zero);
      addTearDown(g.removePointer);
      FluentGroupedVerticalBarChartDelegate mounted() =>
          tester.widget<FluentCartesianChart>(chart).delegate
              as FluentGroupedVerticalBarChartDelegate;
      // The single line point sits on the band centre, which is also where the
      // one bar column is centred, so hovering a bar reports the dot's x as
      // the anchor it stays pinned to. The y is solved by the shell, so it is
      // swept rather than derived.
      await g.moveTo(tester.getCenter(chart));
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(chart);
      final x =
          origin.dx +
          tester
              .widget<FluentChartPopover>(find.byType(FluentChartPopover))
              .anchor
              .dx;
      // 4 is the sweep step and 320 the tallest plot an 350px chart can have;
      // both are test constants.
      for (var y = 0.0; y < 320 && mounted().activeLinePoint == null; y += 4) {
        await g.moveTo(Offset(x, origin.dy + y));
        await tester.pump();
      }
      expect(
        mounted().activeLinePoint,
        '0-0',
        reason:
            'the pointer within the active dot radius makes that dot the '
            'active one, GroupedVerticalBarChart.tsx:916-937',
      );
      expect(
        tester
            .widget<FluentChartPopover>(find.byType(FluentChartPopover))
            .data
            .legend,
        'Trend',
        reason: 'and the dot is the hit region the popover reads',
      );
    });
  });
}
