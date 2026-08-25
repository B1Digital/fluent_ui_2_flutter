import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// VerticalStackedBarChart's page is eight demos and the densest control set in
/// the catalog: five rails on one section, a tri-state bar width on another,
/// four callout variants on a third. All of it lands on a canvas, so the
/// assertions below read the chart's display list through [paintOps] — a
/// segment is a `drawRect`, a rounded stack top is a `drawPath`, a stack total
/// is a `drawParagraph` — and the widget tree is consulted only for the
/// callout, which is the one piece of chrome made of widgets.
void main() {
  const String page = 'charts-verticalstackedbarchart';

  /// The two sections that carry the same seven controls in the same order.
  const List<String> twins = <String>[
    'charts-verticalstackedbarchart--vertical-stacked-bar-default',
    'charts-verticalstackedbarchart--vertical-stacked-bar-negative',
  ];

  group('stacks and seams', () {
    for (final String id in twins) {
      final DocsSection section = sectionOf(id);

      testWidgets('$id draws and removes its lines', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final Finder lines = find.byType(FluentCheckbox).at(0);
        expect(tester.widget<FluentCheckbox>(lines).checked, isTrue);
        expect(_lineStrokes(tester), greaterThan(0));

        // A real mouse on the page's primary knob: the checkbox paints its
        // glyph in a CustomPaint under an interaction wrapper, so one wired
        // only to a synthetic tap would be dead under a pointer.
        await mouseClick(tester, lines);
        expect(tester.widget<FluentCheckbox>(lines).checked, isFalse);
        expect(
          _lineStrokes(tester),
          0,
          reason: 'clearing lineData must take the markers with the stroke',
        );

        await mouseClick(tester, lines);
        expect(_lineStrokes(tester), greaterThan(0));
      });

      testWidgets('$id hides one label per stack', (WidgetTester tester) async {
        await pumpSection(tester, section);
        final Finder hide = find.byType(FluentCheckbox).at(1);
        final int labelled = _paragraphs(tester);
        final int stacks = _stackCount(tester);

        await mouseClick(tester, hide);
        expect(tester.widget<FluentCheckbox>(hide).checked, isTrue);
        // One total per stack, not one per segment: a chart that dropped its
        // tick labels instead would also print "fewer paragraphs".
        expect(_paragraphs(tester), labelled - stacks);

        await mouseClick(tester, hide);
        expect(_paragraphs(tester), labelled);
      });

      testWidgets('$id drops its axis titles and re-margins the plot', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final Finder titles = find.byType(FluentSwitch).at(0);
        expect(tester.widget<FluentSwitch>(titles).checked, isTrue);
        final int titled = _paragraphs(tester);
        final double left = _bars(tester).first.left;

        await tapAndSettle(tester, titles, what: 'the axis-titles switch');
        expect(_paragraphs(tester), titled - 2);
        // The switch swaps the margins as well as the titles, so the plot has
        // to start further left once the y title's reserve is given back.
        expect(_bars(tester).first.left, lessThan(left));

        await tapAndSettle(tester, titles, what: 'the axis-titles switch');
        expect(_paragraphs(tester), titled);
        expect(_bars(tester).first.left, left);
      });

      testWidgets('$id rounds every segment on demand', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final Finder round = find.byType(FluentSwitch).at(1);
        final int segments = _bars(tester).length;
        expect(_rounded(tester), isEmpty);

        await tapAndSettle(tester, round, what: 'the rounded-corners switch');
        expect(_rounded(tester), hasLength(segments));
        expect(
          _rounded(tester).first.blRadiusX,
          3,
          reason: "3 is upstream's own rx for a rounded segment",
        );
        expect(_bars(tester), isEmpty);

        await tapAndSettle(tester, round, what: 'the rounded-corners switch');
        expect(_bars(tester), hasLength(segments));
      });

      testWidgets('$id keeps a second legend lit in multi-select', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, section);
        final List<String> legends = _legendTitles(tester);
        expect(legends.length, greaterThan(1));

        await mouseClick(tester, _legendRow(legends[0]));
        final int one = _highlighted(tester);
        expect(one, greaterThan(0));
        await mouseClick(tester, _legendRow(legends[1]));
        expect(
          _highlighted(tester),
          greaterThan(0),
          reason: 'single selection must move the highlight, not clear it',
        );

        // The switch changes what the next press does; the standing selection
        // survives it, so this adds the first legend back to it.
        await tapAndSettle(
          tester,
          find.byType(FluentSwitch).at(2),
          what: 'the multi-select switch',
        );
        await mouseClick(tester, _legendRow(legends[0]));
        expect(
          _highlighted(tester),
          greaterThan(one),
          reason: 'multiple selection must keep both legends lit',
        );
      });
    }

    // Five sections carry a BarGapMax rail, and it is always the third.
    for (final String id in <String>[
      ...twins,
      'charts-verticalstackedbarchart--vertical-stacked-bar-callout',
      'charts-verticalstackedbarchart--vertical-stacked-bar-custom-'
          'accessibility',
      'charts-verticalstackedbarchart--vertical-stacked-bar-date-axis',
    ]) {
      testWidgets('$id opens and closes its seams', (
        WidgetTester tester,
      ) async {
        await pumpSection(tester, sectionOf(id));
        final Finder gap = find.byType(FluentSlider).at(2);
        final double seamed = _ink(tester);

        await dropSliderAt(tester, gap, 0);
        expect(tester.widget<FluentSlider>(gap).value, 0);
        final double solid = _ink(tester);
        expect(
          solid,
          greaterThan(seamed),
          reason:
              'a gap is cut out of the segments around it, so closing every '
              'gap must give the ink back',
        );

        await dropSliderAt(tester, gap, 1);
        expect(tester.widget<FluentSlider>(gap).value, 10);
        expect(_ink(tester), lessThan(solid));
      });
    }
  });

  group('sizing', () {
    testWidgets('every section resizes with its width and height rails', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Finder chart = find.byType(FluentVerticalStackedBarChart);

        await dropSliderAt(tester, find.byType(FluentSlider).at(0), 0);
        await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
        expect(tester.getSize(chart).width, 200, reason: section.id);
        expect(
          tester.getSize(chart).height,
          greaterThan(900),
          reason: section.id,
        );
      }
    });
  });

  group('vertical stacked bar axis tooltip', () {
    final DocsSection section = sectionOf(
      'charts-verticalstackedbarchart--vertical-stacked-bar-axis-tooltip',
    );

    testWidgets('the barWidth spin button widens every stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      _expectWidth(tester, 16);

      await typeAndCommit(tester, find.byType(FluentSpinButton).at(0), '40');
      _expectWidth(tester, 40);

      await typeAndCommit(tester, find.byType(FluentSpinButton).at(0), '16');
      _expectWidth(tester, 16);
    });

    testWidgets('the maxBarWidth spin button clamps the stacks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await typeAndCommit(tester, find.byType(FluentSpinButton).at(0), '200');
      // maxBarWidth is 100, so a 200px request must be cut to it.
      _expectWidth(tester, 100);

      await typeAndCommit(tester, find.byType(FluentSpinButton).at(1), '30');
      _expectWidth(tester, 30);
    });

    testWidgets("clearing the barWidth checkbox hands the stacks 'auto'", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gate = find.byType(FluentCheckbox).at(0);

      await mouseClick(tester, gate);
      expect(tester.widget<FluentCheckbox>(gate).checked, isFalse);
      expect(
        find.text("'auto'"),
        findsOneWidget,
        reason: 'the spin button is replaced by the literal it stands in for',
      );
      expect(find.byType(FluentSpinButton), findsOneWidget);
      expect(
        _narrowest(tester),
        greaterThan(16),
        reason: "'auto' hands each stack its whole band",
      );

      await mouseClick(tester, gate);
      _expectWidth(tester, 16);
    });

    testWidgets('the inner-padding slider closes the gap between stacks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gate = find.byType(FluentCheckbox).at(1);
      final Finder slider = find.byType(FluentSlider).at(2);
      final double step = _step(tester);

      // Disabled until its checkbox is ticked: the rail must refuse to move
      // while the prop it feeds is null.
      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 0.67);
      expect(_step(tester), step);

      await tapAndSettle(tester, gate, what: 'the inner-padding checkbox');
      await dropSliderAt(tester, slider, 0);
      expect(tester.widget<FluentSlider>(slider).value, 0);
      expect(
        _step(tester),
        closeTo(_narrowest(tester), 0.01),
        reason: 'no inner padding must leave the stacks flank to flank',
      );
    });

    testWidgets('the outer-padding slider moves the first stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = find.byType(FluentSlider).at(3);

      await tapAndSettle(
        tester,
        find.byType(FluentCheckbox).at(2),
        what: 'the outer-padding checkbox',
      );
      // Measured after the gate: ticking it turns an absent padding into an
      // explicit 0, which is already a different chart. The rail is what this
      // test owns.
      final Rect first = _bars(tester).first;

      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 1);
      expect(_bars(tester).first, isNot(first));

      await dropSliderAt(tester, slider, 0);
      expect(_bars(tester).first, first);
    });

    testWidgets('the tick radios swap wrapping for truncation', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      final int truncated = _paragraphs(tester);

      await mouseClick(tester, find.text('Wrap X Axis Ticks'));
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'WrapTickValues',
      );
      expect(
        _paragraphs(tester),
        greaterThan(truncated),
        reason:
            'wrapping splits a long tick label into lines, and each line '
            'is its own paragraph',
      );

      await mouseClick(tester, find.text('Show Tooltip at X Axis Ticks'));
      expect(_paragraphs(tester), truncated);
    });

    testWidgets('the rounded-corners switch swaps every segment for a rrect', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final int segments = _bars(tester).length;

      await tapAndSettle(
        tester,
        find.byType(FluentSwitch).at(1),
        what: 'the rounded-corners switch',
      );
      expect(_rounded(tester), hasLength(segments));
    });

    testWidgets('the gradient switch is inert by design', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder gradient = find.byType(FluentSwitch).at(0);
      final List<Rect> before = _bars(tester);
      final List<Color> fills = _fills(tester);

      await tapAndSettle(tester, gradient, what: 'the gradient switch');
      expect(tester.widget<FluentSwitch>(gradient).checked, isTrue);
      // `enableGradient` has no counterpart on the port, which paints flat
      // segment fills; the switch is kept only so the section carries
      // upstream's control set. This is what would catch it being wired up
      // without the page's own comment following.
      expect(_bars(tester), before);
      expect(_fills(tester), fills);
    });
  });

  group('vertical stacked bar callout', () {
    final DocsSection section = sectionOf(
      'charts-verticalstackedbarchart--vertical-stacked-bar-callout',
    );

    testWidgets('hovering a segment raises the stack callout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      final TestGesture mouse = await _hoverSegment(tester, 0);
      // Fails today: `FluentVerticalStackedBarChartDelegate.buildHitRegions`
      // returns an empty list, so the shell has nothing to hover, nothing to
      // focus and nothing to anchor a popover to. The whole point of this
      // section — four callout variants — is unreachable, and so are
      // `isCalloutForStack`, `props.popoverBuilder` and `onBarClick`.
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'a pointer inside a segment must raise its callout',
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('the callout radios reconfigure the chart', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentVerticalStackedBarChart);
      expect(_chart(tester, chart).isCalloutForStack, isTrue);

      await mouseClick(
        tester,
        find.text(
          'Single callout (won\'t work if '
          'lines are present)',
        ),
      );
      expect(_chart(tester, chart).isCalloutForStack, isFalse);
      expect(_chart(tester, chart).props.popoverBuilder, isNull);

      await mouseClick(tester, find.text('stack callout with custom content'));
      expect(_chart(tester, chart).isCalloutForStack, isTrue);
      expect(
        _chart(tester, chart).props.popoverBuilder,
        isNotNull,
        reason:
            'the two custom variants swap the callout body for the '
            'demo\'s own builder',
      );
    });

    testWidgets('the barWidth rail widens every stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = find.byType(FluentSlider).at(3);
      _expectWidth(tester, 16);

      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 50);
      expect(_narrowest(tester), greaterThan(16));

      await dropSliderAt(tester, slider, 0);
      expect(tester.widget<FluentSlider>(slider).value, 1);
      _expectWidth(tester, 1);
    });

    testWidgets('the show-lines checkbox draws and removes the lines', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_lineStrokes(tester), greaterThan(0));

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_lineStrokes(tester), 0);

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_lineStrokes(tester), greaterThan(0));
    });
  });

  group('vertical stacked bar custom accessibility', () {
    testWidgets('the show-lines checkbox draws and removes the lines', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf(
          'charts-verticalstackedbarchart--vertical-stacked-bar-custom-'
          'accessibility',
        ),
      );
      expect(_lineStrokes(tester), greaterThan(0));

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_lineStrokes(tester), 0);

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_lineStrokes(tester), greaterThan(0));
    });
  });

  group('vertical stacked bar date axis', () {
    final DocsSection section = sectionOf(
      'charts-verticalstackedbarchart--vertical-stacked-bar-date-axis',
    );

    testWidgets('the corner-radius rail rounds the top of every stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder radius = find.byType(FluentSlider).at(3);
      final int arched = _arched(tester);
      expect(arched, greaterThan(0));

      await dropSliderAt(tester, radius, 0);
      expect(tester.widget<FluentSlider>(radius).value, 0);
      expect(
        _arched(tester),
        0,
        reason: 'a zero radius must leave every stack top a plain rect',
      );

      await dropSliderAt(tester, radius, 1);
      expect(tester.widget<FluentSlider>(radius).value, 10);
      expect(
        _arched(tester),
        greaterThanOrEqualTo(arched),
        reason: 'a bigger radius can only arch more tops, never fewer',
      );
    });

    testWidgets('the minimum-height rail lifts the flattest segment', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder floor = find.byType(FluentSlider).at(4);
      final double flattest = _flattest(tester);

      await dropSliderAt(tester, floor, 1);
      expect(tester.widget<FluentSlider>(floor).value, 10);
      expect(
        _flattest(tester),
        greaterThan(flattest),
        reason: 'barMinimumHeight is a floor under every segment',
      );

      await dropSliderAt(tester, floor, 0);
      expect(
        _flattest(tester),
        lessThanOrEqualTo(flattest),
        reason: 'the rail bottoms out at 0, one below the seeded floor of 1',
      );
    });

    testWidgets('the callout radio reconfigures the chart', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentVerticalStackedBarChart);
      expect(_chart(tester, chart).isCalloutForStack, isTrue);

      await mouseClick(tester, find.text('Single callout'));
      expect(_chart(tester, chart).isCalloutForStack, isFalse);
    });

    testWidgets('the explicit tick values label the axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Fails today. The section names nine tick values and a `%m/%d`
      // formatter; the formatter lands and the tick values do not, so the axis
      // labels generated quarterly ticks instead. `FluentCartesianChartProps
      // .tickValues` reaches the domain solve only — the three x builders are
      // handed `delegate.tickParams`, which no delegate ever fills in.
      expect(_painter(tester).xAxis.tickLabels, <String>[
        '03/01',
        '05/01',
        '07/01',
        '09/01',
        '11/01',
        '02/01',
        '05/01',
        '07/01',
        '09/01',
      ]);
    });

    testWidgets('clicking a segment reports it to onBarClick', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<String> reported = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          reported.add(message ?? '');
      // Restored inside the body rather than in a tearDown, the way the line
      // chart's click test does it: `_verifyInvariants` runs at the end of the
      // test body and before any tearDown, so a `debugPrint` still overridden
      // there fails the test with "a foundation debug variable was changed"
      // however the click itself went.
      try {
        await _clickSegment(tester, 0);
      } finally {
        debugPrint = original;
      }
      expect(
        reported.where((String line) => line.startsWith('clicked')),
        isNotEmpty,
        reason: 'the section hands the chart an onBarClick and prints from it',
      );
    });
  });

  group('vertical stacked bar secondary y axis', () {
    testWidgets('the sales target is plotted against its own scale', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf(
          'charts-verticalstackedbarchart--vertical-stacked-bar-secondary-y-'
          'axis',
        ),
      );
      final FluentCartesianChartPainter painter = _painter(tester);
      expect(painter.yAxisSecondary, isNotNull);
      expect(
        painter.yAxisSecondary!.tickLabels,
        isNot(painter.yAxisPrimary.tickLabels),
        reason: 'a secondary axis over its own domain must label differently',
      );
      expect(_lineStrokes(tester), greaterThan(0));
    });
  });

  group('vertical stacked bar axis category order', () {
    final DocsSection section = sectionOf(
      'charts-verticalstackedbarchart--vertical-stacked-bar-axis-category-'
      'order',
    );

    testWidgets('the order dropdown sorts the categories', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);
      // The band scale's domain is the category order the chart actually
      // plotted, which is what the prop claims to control; the drawn tick
      // labels are a subset of it once the axis starts hiding collisions.
      final List<Object> asAuthored = _categories(tester);
      expect(asAuthored.length, greaterThan(1));

      expect(
        await pickDropdown<String>(tester, dropdown, 'category ascending'),
        'category ascending',
      );
      final List<Object> ascending = _categories(tester);
      expect(ascending, (List<Object>.of(asAuthored)..sort(_byName)));

      expect(
        await pickDropdown<String>(tester, dropdown, 'category descending'),
        'category descending',
      );
      expect(_categories(tester), ascending.reversed.toList());
    });

    testWidgets('"Change data" replaces the plot', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final List<Rect> before = _bars(tester);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentButton, 'Change data'),
        what: 'the Change data button',
      );
      expect(
        _bars(tester),
        isNot(before),
        reason: 'the button advances the generator, so the stacks must change',
      );
    });

    testWidgets('the data-size rail changes the number of stacks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder size = find.byType(FluentSlider).at(2);
      final int categories = _categories(tester).length;

      await dropSliderAt(tester, size, 1);
      expect(tester.widget<FluentSlider>(size).value, 50);
      expect(_categories(tester).length, greaterThan(categories));

      await dropSliderAt(tester, size, 0);
      expect(
        find.descendant(
          of: find.byType(FluentVerticalStackedBarChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
        reason: 'an empty series draws no plot at all, only its live region',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The plot's own `CustomPaint`; the legend's swatches follow it in tree order.
Finder get _canvas => find.descendant(
  of: find.byType(FluentVerticalStackedBarChart),
  matching: find.byType(CustomPaint),
);

/// The chart's display list.
List<RecordedInvocation> _ops(WidgetTester tester) => paintOps(tester, _canvas);

/// Every square-cornered segment the chart drew, in paint order.
List<Rect> _bars(WidgetTester tester) => <Rect>[
  for (final ({Paint paint, Rect rect}) mark in paintedRects(_ops(tester)))
    mark.rect,
];

/// The fill each segment was painted with, alpha included.
List<Color> _fills(WidgetTester tester) => <Color>[
  for (final ({Paint paint, Rect rect}) mark in paintedRects(_ops(tester)))
    mark.paint.color,
];

/// The segments drawn as RRects, which are absent from [_bars].
List<RRect> _rounded(WidgetTester tester) =>
    opArgs<RRect>(_ops(tester), #drawRRect);

/// How many stack tops were drawn as an arched path rather than a rect.
///
/// `barCornerRadius` is per stack, not per segment: only the topmost segment of
/// a stack — and only one taller than the radius — takes the arc.
int _arched(WidgetTester tester) => countOps(_ops(tester), #drawPath);

/// Asserts every stack was drawn [expected] wide.
///
/// With a tolerance, not as a set: a band width is a division, so two stacks
/// that agree to the pixel can still differ in the fifteenth decimal place and
/// a bare `Set` comparison would call that two widths.
void _expectWidth(WidgetTester tester, double expected) {
  final List<Rect> bars = _bars(tester);
  expect(bars, isNotEmpty);
  for (final Rect bar in bars) {
    expect(bar.width, closeTo(expected, 0.001));
  }
}

/// The narrowest stack on screen.
double _narrowest(WidgetTester tester) => _bars(tester).fold(
  double.infinity,
  (double least, Rect bar) => bar.width < least ? bar.width : least,
);

/// Total painted segment height, which is what a seam eats into.
double _ink(WidgetTester tester) =>
    _bars(tester).fold(0, (double sum, Rect bar) => sum + bar.height);

/// The height of the shortest segment on screen.
double _flattest(WidgetTester tester) => _bars(tester).fold(
  double.infinity,
  (double least, Rect bar) => bar.height < least ? bar.height : least,
);

/// How many stacks are on screen, counted by their distinct left edges.
int _stackCount(WidgetTester tester) =>
    _bars(tester).map((Rect bar) => bar.left).toSet().length;

/// The distance between the starts of two neighbouring stacks.
double _step(WidgetTester tester) {
  final List<double> lefts = _bars(
    tester,
  ).map((Rect bar) => bar.left).toSet().toList()..sort();
  return lefts[1] - lefts[0];
}

/// How many segments are at full opacity — the legend-highlight count.
int _highlighted(WidgetTester tester) => paintedRects(
  _ops(tester),
).where((({Paint paint, Rect rect}) mark) => mark.paint.color.a > 0.5).length;

/// How many strokes belong to the overlaid lines.
///
/// This chart draws its overlay as plain segments rather than a path, and it
/// draws a marker only on a highlighted legend or the active x — so with
/// nothing selected the dots are absent by design and the strokes are all
/// there is. Axis lines and gridlines come off the same `drawLine`, so the
/// round cap is what separates them: the axis painter leaves the default butt
/// cap, and every overlay stroke asks for `StrokeCap.round`.
int _lineStrokes(WidgetTester tester) => opArgs<Paint>(
  _ops(tester),
  #drawLine,
  at: 2,
).where((Paint paint) => paint.strokeCap == StrokeCap.round).length;

/// Every run of text the chart painted — ticks, totals, axis titles.
int _paragraphs(WidgetTester tester) => countOps(_ops(tester), #drawParagraph);

/// The painter the chart handed the canvas, for the geometry the display list
/// does not spell out.
FluentCartesianChartPainter _painter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).first;

/// The category order the x scale was built with.
List<Object> _categories(WidgetTester tester) =>
    _painter(tester).xAxis.scale.domain;

/// Compares two category names the way a string sort does.
int _byName(Object a, Object b) => '$a'.compareTo('$b');

/// The chart widget itself, for the props the demo sets on it.
FluentVerticalStackedBarChart _chart(WidgetTester tester, Finder finder) =>
    tester.widget<FluentVerticalStackedBarChart>(finder);

/// The legend titles in strip order.
List<String> _legendTitles(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row
      in tester.widgetList<FluentChartLegendRow>(
        find.byType(FluentChartLegendRow),
      ))
    row.item.title,
];

/// The legend row titled [title], re-resolved on every call.
Finder _legendRow(String title) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentChartLegendRow && widget.item.title == title,
);

/// Parks a real mouse in the middle of the [index]-th painted segment.
///
/// A segment is canvas ink, not a widget, so the rect comes out of the display
/// list in plot coordinates and is carried to the screen by the plot's origin.
Future<TestGesture> _hoverSegment(WidgetTester tester, int index) async {
  final Rect segment = _bars(tester)[index];
  final TestGesture mouse = await mouseHoverAt(
    tester,
    tester.getTopLeft(_canvas.first) + segment.center,
    what: 'segment $index',
  );
  await settle(tester);
  return mouse;
}

/// Clicks the middle of the [index]-th painted segment with a real mouse.
Future<void> _clickSegment(WidgetTester tester, int index) async {
  final Rect segment = _bars(tester)[index];
  await mouseClickAt(
    tester,
    tester.getTopLeft(_canvas.first) + segment.center,
    what: 'segment $index',
  );
}
