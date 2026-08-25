import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// GroupedVerticalBarChart's page is four demos over the same four quarters.
/// Everything a knob here moves is painted into one `CustomPaint` — the bars,
/// their per-column totals, the two overlaid line series — so the assertions
/// read the chart's display list through [paintOps] rather than the widget
/// tree. The one thing that *is* a widget is the popover, and the callout
/// radios are tested through it: press a bar, read what came up.
void main() {
  const String page = 'charts-groupedverticalbarchart';

  group('grouped vertical bar default', () {
    final DocsSection section = sectionOf(
      'charts-groupedverticalbarchart--grouped-vertical-bar-default',
    );

    testWidgets('the width and height sliders resize the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGroupedVerticalBarChart);
      final Finder width = find.byType(FluentSlider).at(0);
      final Finder height = find.byType(FluentSlider).at(1);
      expect(tester.getSize(chart), const Size(650, 350));
      final double reach = _bars(tester).last.right;

      await dropSliderAt(tester, width, 1);
      expect(
        tester.getSize(chart).width,
        tester.widget<FluentSlider>(width).value,
      );
      expect(
        _bars(tester).last.right,
        greaterThan(reach),
        reason: 'a wider box must spread the groups, not just pad them',
      );

      final double tallest = _tallest(tester);
      await dropSliderAt(tester, height, 1);
      expect(
        tester.getSize(chart).height,
        tester.widget<FluentSlider>(height).value,
      );
      expect(_tallest(tester), greaterThan(tallest));

      await dropSliderAt(tester, width, 0);
      await dropSliderAt(tester, height, 0);
      expect(tester.getSize(chart), const Size(200, 200));
    });

    testWidgets('hiding the labels drops one paragraph per column', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder hide = find.byType(FluentCheckbox);
      final int bars = _bars(tester).length;
      final int labelled = _paragraphs(tester);
      expect(bars, 16, reason: 'four quarters of four series');

      // A real mouse on the page's primary knob. The checkbox paints its glyph
      // in a CustomPaint under an interaction wrapper, so a control wired only
      // to a synthetic tap would be dead under a pointer.
      await mouseClick(tester, hide);
      expect(tester.widget<FluentCheckbox>(hide).checked, isTrue);
      // One total per (category, legend) column, and every column here holds a
      // single bar.
      expect(_paragraphs(tester), labelled - bars);

      await mouseClick(tester, hide);
      expect(_paragraphs(tester), labelled);
    });
  });

  group('grouped vertical bar negative', () {
    final DocsSection section = sectionOf(
      'charts-groupedverticalbarchart--grouped-vertical-bar-negative',
    );

    testWidgets('the barWidth slider is clamped by maxBarWidth', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = find.byType(FluentSlider).at(2);
      expect(_widths(tester), <double>{16});

      await dropSliderAt(tester, slider, 0);
      expect(tester.widget<FluentSlider>(slider).value, 1);
      expect(_widths(tester), <double>{1});

      await dropSliderAt(tester, slider, 1);
      expect(tester.widget<FluentSlider>(slider).value, 50);
      for (final double width in _widths(tester)) {
        expect(
          width,
          closeTo(24, 0.001),
          reason:
              "maxBarWidth defaults to 24, so the slider's top half is a "
              'no-op by design',
        );
      }
    });

    testWidgets('the rounded-corners switch swaps every bar for a rrect', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder round = find.byType(FluentSwitch).at(0);
      final int bars = _bars(tester).length;
      expect(_rounded(tester), isEmpty);

      await tapAndSettle(tester, round, what: 'the rounded-corners switch');
      expect(_rounded(tester), hasLength(bars));
      expect(
        _rounded(tester).first.blRadiusX,
        3,
        reason: "3 is upstream's own rx for a rounded bar",
      );
      expect(_bars(tester), isEmpty);

      await tapAndSettle(tester, round, what: 'the rounded-corners switch');
      expect(_bars(tester), hasLength(bars));
    });

    testWidgets('hiding the labels drops one paragraph per column', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder hide = find.byType(FluentCheckbox);
      final int bars = _bars(tester).length;
      final int labelled = _paragraphs(tester);

      await mouseClick(tester, hide);
      expect(_paragraphs(tester), labelled - bars);

      await mouseClick(tester, hide);
      expect(_paragraphs(tester), labelled);
    });

    testWidgets('the multi-select switch keeps a second legend lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<String> legends = _legendTitles(tester);
      expect(legends.length, greaterThan(1));
      final int perLegend = _bars(tester).length ~/ legends.length;

      await mouseClick(tester, _legendRow(legends[0]));
      expect(_highlighted(tester), perLegend);
      await mouseClick(tester, _legendRow(legends[1]));
      expect(
        _highlighted(tester),
        perLegend,
        reason:
            'single selection must drop the first legend when the second '
            'is picked',
      );

      // The switch changes what the next press does; the standing selection
      // survives it, so this adds the first legend back to it.
      await tapAndSettle(
        tester,
        find.byType(FluentSwitch).at(1),
        what: 'the multi-select switch',
      );
      await mouseClick(tester, _legendRow(legends[0]));
      expect(_highlighted(tester), perLegend * 2);
    });

    testWidgets('the callout radios commit while the demo stays inert', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      final Finder chart = find.byType(FluentGroupedVerticalBarChart);

      await mouseClick(tester, find.text('Stacked callout'));
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'stackedCallout',
      );
      // Upstream compares the radio against 'StackCallout' while its own
      // options carry 'singleCallout' and 'stackedCallout', so neither choice
      // ever turns the stack callout on. The port keeps the same inert
      // comparison, and this is the assertion that would catch it being
      // "fixed" without the docs following.
      expect(
        tester.widget<FluentGroupedVerticalBarChart>(chart).isCalloutForStack,
        isFalse,
      );
    });
  });

  group('grouped vertical bar secondary y axis', () {
    final DocsSection section = sectionOf(
      'charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis',
    );

    testWidgets('the second series is plotted against its own scale', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentCartesianChartPainter painter = _painter(tester);
      expect(painter.yAxisSecondary, isNotNull);
      expect(
        painter.yAxisSecondary!.tickLabels,
        isNot(painter.yAxisPrimary.tickLabels),
        reason: 'a secondary axis over its own domain must label differently',
      );
      expect(_bars(tester), hasLength(8));
    });

    testWidgets('the sliders resize the plot', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGroupedVerticalBarChart);
      expect(tester.getSize(chart), const Size(700, 300));

      await dropSliderAt(tester, find.byType(FluentSlider).at(0), 0);
      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(chart).width, 200);
      expect(tester.getSize(chart).height, greaterThan(900));
    });
  });

  group('grouped vertical bar chart line', () {
    final DocsSection section = sectionOf(
      'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line',
    );

    testWidgets('both line series are drawn over the bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_bars(tester), hasLength(16));
      // Two series of four points, each dot a fill and a ring.
      expect(_dots(tester), 16);
    });

    testWidgets('hovering a bar raises its callout and lifting it clears it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      final TestGesture mouse = await _hoverBar(tester, 0);
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'a pointer inside a bar must raise its callout',
      );
      expect(_popoverText(tester), contains('Jan - Mar'));

      await mouseAway(tester, mouse);
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'the callout belongs to the pointer and must leave with it',
      );
    });

    testWidgets('the callout radio widens the popover to the whole stack', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      TestGesture mouse = await _hoverBar(tester, 0);
      final int single = _popoverText(tester).length;
      expect(single, greaterThan(0));
      await mouseAway(tester, mouse);

      await mouseClick(tester, find.text('Stack Callout'));
      expect(
        tester
            .widget<FluentGroupedVerticalBarChart>(
              find.byType(FluentGroupedVerticalBarChart),
            )
            .isCalloutForStack,
        isTrue,
      );
      mouse = await _hoverBar(tester, 0);
      expect(
        _popoverText(tester).length,
        greaterThan(single),
        reason:
            'a stack callout lists every series in the category, not just '
            'the bar under the pointer',
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('the multi-select switch keeps a second line series lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // This section's strip leads with its two line series and folds the four
      // bar series into the overflow, so the lines are what a pointer can
      // reach — and a line's selection dims every bar, which is its own
      // assertion.
      final List<String> lines = _legendTitles(tester).take(2).toList();
      expect(lines, <String>['From_Legacy_to_O365', 'All']);

      await mouseClick(tester, _legendRow(lines[0]));
      expect(
        _highlighted(tester),
        0,
        reason: 'selecting a line leaves no bar in the selection',
      );
      expect(_dimmedDots(tester), 4, reason: "the other line's four dots");

      await mouseClick(tester, _legendRow(lines[1]));
      expect(_dimmedDots(tester), 4);

      await tapAndSettle(
        tester,
        find.byType(FluentSwitch),
        what: 'the multi-select switch',
      );
      await mouseClick(tester, _legendRow(lines[0]));
      expect(
        _dimmedDots(tester),
        0,
        reason: 'multiple selection must leave both lines at full strength',
      );
    });
  });

  group('sizing', () {
    // The negative and line sections carry their own width and height rails,
    // and both reflow to a minimum width internally — which is exactly where a
    // demo could stop honouring the number the slider reports.
    for (final String id in <String>[
      'charts-groupedverticalbarchart--grouped-vertical-bar-negative',
      'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line',
    ]) {
      testWidgets('$id resizes with its sliders', (WidgetTester tester) async {
        await pumpSection(tester, sectionOf(id));
        final Finder chart = find.byType(FluentGroupedVerticalBarChart);
        expect(tester.getSize(chart), const Size(700, 400));

        await dropSliderAt(tester, find.byType(FluentSlider).at(0), 1);
        await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
        expect(
          tester.getSize(chart).width,
          tester.widget<FluentSlider>(find.byType(FluentSlider).at(0)).value,
        );
        expect(tester.getSize(chart).height, 200);
      });
    }
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
  of: find.byType(FluentGroupedVerticalBarChart),
  matching: find.byType(CustomPaint),
);

/// The chart's display list.
List<RecordedInvocation> _ops(WidgetTester tester) => paintOps(tester, _canvas);

/// Every square-cornered bar the chart drew, in paint order.
List<Rect> _bars(WidgetTester tester) => <Rect>[
  for (final ({Paint paint, Rect rect}) mark in paintedRects(_ops(tester)))
    mark.rect,
];

/// The rounded bars, which are RRects and so are absent from [_bars].
List<RRect> _rounded(WidgetTester tester) =>
    opArgs<RRect>(_ops(tester), #drawRRect);

/// The distinct widths the bars were drawn at.
Set<double> _widths(WidgetTester tester) =>
    _bars(tester).map((Rect bar) => bar.width).toSet();

/// How many bars are at full opacity — the legend-highlight count.
///
/// A bar filtered out by the legend keeps its colour and drops to a tenth of
/// its alpha, so alpha is the only place a legend selection reaches the canvas.
int _highlighted(WidgetTester tester) => paintedRects(
  _ops(tester),
).where((({Paint paint, Rect rect}) mark) => mark.paint.color.a > 0.5).length;

/// The height of the tallest bar.
double _tallest(WidgetTester tester) => _bars(
  tester,
).fold(0, (double best, Rect bar) => bar.height > best ? bar.height : best);

/// Every line-marker circle: the overlaid series draw a fill and a ring each.
int _dots(WidgetTester tester) => countOps(_ops(tester), #drawCircle);

/// Every run of text the chart painted — ticks, totals, axis titles.
int _paragraphs(WidgetTester tester) => countOps(_ops(tester), #drawParagraph);

/// The painter the chart handed the canvas, for the geometry the display list
/// does not spell out.
FluentCartesianChartPainter _painter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).first;

/// The legend titles in strip order.
///
/// Titles rather than finders: pressing a row rebuilds the whole strip, and a
/// `find.byWidget` on the old row would then match nothing.
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

/// Parks a real mouse in the middle of the [index]-th painted bar.
///
/// A bar is canvas ink, not a widget, so there is nothing to hand `mouseHover`:
/// the rect comes out of the display list in plot coordinates and is carried to
/// the screen by the plot's own origin. The caller owns the gesture and must
/// hand it to [mouseAway].
Future<TestGesture> _hoverBar(WidgetTester tester, int index) async {
  final Rect bar = _bars(tester)[index];
  final TestGesture mouse = await mouseHoverAt(
    tester,
    tester.getTopLeft(_canvas.first) + bar.center,
    what: 'bar $index',
  );
  await settle(tester);
  return mouse;
}

/// The line-marker rings drawn dimmed.
///
/// Each dot is a fill and a ring, and only the ring carries the series'
/// opacity, so counting the dimmed ones is how a line's legend selection is
/// read off the canvas.
int _dimmedDots(WidgetTester tester) => opArgs<Paint>(
  _ops(tester),
  #drawCircle,
  at: 2,
).where((Paint paint) => paint.color.a < 0.5).length;

/// Every line of text inside the open popover.
List<String> _popoverText(WidgetTester tester) => <String>[
  for (final Text text in tester.widgetList<Text>(
    find.descendant(
      of: find.byType(FluentChartPopover),
      matching: find.byType(Text),
    ),
  ))
    if ((text.data ?? '').isNotEmpty) text.data!,
];
