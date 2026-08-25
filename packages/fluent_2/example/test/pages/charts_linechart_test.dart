import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// LineChart's page is thirteen demos over one component, and every one of them
/// wires the same two size sliders to the box the chart is given. What differs
/// is the second row of knobs — a shapes switch, an axis-titles switch, a UTC
/// checkbox, a callout radio, a pair of scale radios — and each of those has to
/// be read off the *painter*, not off the widget that owns it: a cartesian chart
/// paints its axes, its marks and its titles onto a single [CustomPaint], so a
/// knob that moved nothing would still leave every `Text` in the demo untouched.
void main() {
  const String page = 'charts-linechart';

  group('line chart basic', () {
    final DocsSection section = sectionOf('charts-linechart--line-chart-basic');

    testWidgets('the size sliders resize the chart and round trip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentLineChart)),
        const Size(700, 300),
      );

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      expect(tester.getSize(find.byType(FluentLineChart)).width, 1000);
      // The box is only half the claim: the plot has to be re-solved into it,
      // or the chart would be a 700-wide drawing stretched inside a 1000-wide
      // hole.
      expect(chartPainter(tester).layout.plotRect.width, greaterThan(600));

      await dropSliderAt(tester, sliderNamed('Change Height'), 1);
      expect(tester.getSize(find.byType(FluentLineChart)).height, 1000);

      await dropSliderAt(tester, sliderNamed('Change Width'), 0);
      expect(tester.getSize(find.byType(FluentLineChart)).width, 200);
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = sliderNamed('Change Width');
      await tester.ensureVisible(slider);
      await settle(tester);

      // A press with travel, not a synthetic tap: the demo hangs its chart in a
      // horizontal scroller and the whole section sits in a vertical one, so a
      // mouse that counts as a drag device would have this click swallowed by a
      // scrollable before the rail ever saw it.
      final Rect rail = tester.getRect(slider);
      await mouseClickAt(
        tester,
        Offset(rail.right - 1, rail.center.dy),
        what: 'the width rail at its far end',
      );
      expect(
        tester.getSize(find.byType(FluentLineChart)).width,
        greaterThan(700),
        reason: 'a mouse press on the rail must move the thumb',
      );
    });

    testWidgets('the multiple-shapes switch changes the markers it paints', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder toggle = switchLabelled('multiple shapes');

      // Flag off, `LineChart.tsx:492`'s cycle is pinned to 0, so every series
      // draws the same shape; on, the cycle runs over the series index.
      expect(shapeIndexes(tester), <int?>{null, 0});

      await tapAndSettle(tester, toggle, what: 'the multiple-shapes switch');
      expect(
        find.text('Enabled multiple shapes for each line'),
        findsOneWidget,
      );
      expect(
        shapeIndexes(tester).length,
        greaterThan(2),
        reason: 'each line must take its own marker shape',
      );

      await tapAndSettle(tester, toggle, what: 'the multiple-shapes switch');
      expect(shapeIndexes(tester), <int?>{null, 0});
      expect(
        find.text('Disabled multiple shapes for each line'),
        findsOneWidget,
      );
    });

    testWidgets('the axis-titles switch gives the plot the margin back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder toggle = switchLabelled('axis titles');
      final Rect titled = chartPainter(tester).layout.plotRect;

      await tapAndSettle(tester, toggle, what: 'the axis-titles switch');
      final Rect bare = chartPainter(tester).layout.plotRect;
      // `_applyTitleMargins` (`CartesianChart.tsx:684-696`) buys each title its
      // own margin, so dropping both is a wider *and* taller plot. Asserting the
      // title strings themselves is impossible — they are painted into the
      // canvas, not mounted as Text.
      expect(bare.width, greaterThan(titled.width));
      expect(bare.height, greaterThan(titled.height));

      await tapAndSettle(tester, toggle, what: 'the axis-titles switch');
      expect(chartPainter(tester).layout.plotRect, titled);
    });

    testWidgets('the UTC checkbox changes the dates the chart shows', (
      WidgetTester tester,
    ) async {
      // The demo's points are `DateTime.utc`, which is upstream's
      // `new Date('…Z')`. Unticking "Use UTC time" is supposed to re-read those
      // instants in the viewer's own zone — that is the only thing the knob is
      // for. A runner already sitting in UTC has nothing to convert, so there is
      // no difference to demand of it.
      if (DateTime.now().timeZoneOffset == Duration.zero) {
        markTestSkipped('the runner is in UTC, where the knob cannot show');
        return;
      }
      await pumpSection(tester, section);
      final List<int> utcTicks = tickInstants(tester);
      final String utcDate = await popoverDateOfFourthPoint(tester);

      await tapAndSettle(tester, find.byType(FluentCheckbox), what: 'Use UTC');
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).checked,
        isFalse,
      );
      expect(chartPainter(tester).props.useUTC, false);
      // The tick LABELS are the wrong thing to read here, and asserting on them
      // was this test's own bug: `ScaleTime` re-creates every tick in its own
      // zone (`internal/d3/scale_time.dart:30`), so a local scale ticks at local
      // midnight and a UTC one at UTC midnight and both render `Mar 03, 12 AM` —
      // exactly as upstream's `d3ScaleTime` plus `toLocaleString` does. What the
      // knob moves is the INSTANT each tick sits on.
      expect(
        tickInstants(tester),
        isNot(utcTicks),
        reason: 'local time must place the ticks on different instants',
      );
      // And the popover date, which is the one label a caller-supplied
      // `DateTime.utc` reaches unconverted: it must read the viewer's clock and
      // name the viewer's zone once the knob is off.
      final String localDate = await popoverDateOfFourthPoint(tester);
      expect(utcDate, '03/04/2020, 12:00:00 AM UTC');
      expect(
        localDate,
        isNot(endsWith('UTC')),
        reason: 'the popover must re-read the instant in the viewer zone',
      );
      expect(localDate, isNot(utcDate));
    });

    testWidgets('the callout radio switches the popover between one series '
        'and the stack', (WidgetTester tester) async {
      await pumpSection(tester, section);
      // Stack Callout is the demo's default, and the second keyboard stop is a
      // date both lines have a reading at.
      await focusOn(tester, find.byType(FluentLineChart));
      await sendArrows(tester, 2);
      expect(popoverTexts(tester), contains('From_Legacy_to_O365'));
      expect(popoverTexts(tester), contains('All'));

      // Unmounted before the second half rather than re-pumped over the top of
      // it: `pumpSection` rebuilds the same widget in the same slot, so the
      // demo's State — the roving focus and the radio included — would survive
      // into a run that is supposed to start clean.
      await expectCleanTeardown(tester, section.id);
      await pumpSection(tester, section);
      await tapAndSettle(
        tester,
        find.text('Single Callout'),
        what: 'the radio',
      );
      await focusOn(tester, find.byType(FluentLineChart));
      await sendArrows(tester, 2);
      final List<String> single = popoverTexts(tester);
      expect(
        single.where(
          (String text) => text == 'All' || text == 'From_Legacy_to_O365',
        ),
        hasLength(1),
        reason: 'a single callout names only the hovered line',
      );
    });

    testWidgets('a real pointer on a data point opens and closes its popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      final TestGesture mouse = await hoverAt(
        tester,
        markCentre(tester, series: 0, point: 3),
        what: 'the fourth point of the first line',
      );
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'the hover latch is 8px wide and the mark is under the cursor',
      );
      expect(popoverTexts(tester), contains('248,000'));

      // `onExit` clears the hover (`CartesianChart.tsx:749`), so lifting the
      // pointer must take the popover with it rather than leaving it pinned.
      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });

    testWidgets('clicking a data point fires the callback it declares', (
      WidgetTester tester,
    ) async {
      // Every point in this demo carries an `onDataPointClick` that prints, and
      // the first series carries an `onLineClick`. Upstream binds the click
      // handler to each rendered marker (`LineChart.tsx:908`, `:1074`,
      // `:1151`), so a click has to reach one of them. Restored inside the body
      // rather than in a tearDown: the framework verifies its debug hooks
      // before tearDowns run.
      final List<String> printed = <String>[];
      final DebugPrintCallback original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.add(message ?? '');
      try {
        await pumpSection(tester, section);
        await tester.tapAt(markCentre(tester, series: 0, point: 3));
        await settle(tester);
      } finally {
        debugPrint = original;
      }
      expect(
        printed,
        isNotEmpty,
        reason: 'the point declares onDataPointClick and nothing invoked it',
      );
    });
  });

  group('line chart legend', () {
    final DocsSection section = sectionOf('charts-linechart--line-chart-basic');

    testWidgets('hovering a legend dims every other line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(markerOpacity(tester, 'From_Legacy_to_O365'), 1);

      // `hoverAction` (`LineChart.tsx:409-412`) is what makes a legend a filter
      // preview, and it is the same opacity path a selection drives.
      final double dimmed = await whileHovering(
        tester,
        find.widgetWithText(FluentChartLegendRow, 'All'),
        () => markerOpacity(tester, 'From_Legacy_to_O365'),
      );
      expect(dimmed, lessThan(1));
      expect(markerOpacity(tester, 'From_Legacy_to_O365'), 1);
    });

    testWidgets('clicking a legend selects it and dims the other lines', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(
        tester,
        find.widgetWithText(FluentChartLegendRow, 'All'),
      );
      // The row itself moves — that half is the shell's own state.
      expect(legendRow(tester, 'All').selected, isTrue);
      expect(legendRow(tester, 'From_Legacy_to_O365').dimmed, isTrue);
      // …and the plot must follow it, exactly as the hover does.
      // `_handleSingleLegendSelectionAction` (`LineChart.tsx:356-364`) sets the
      // selected legend, and `_legendHighlighted` (`:1817`) then dims every
      // other line and marker.
      expect(
        markerOpacity(tester, 'From_Legacy_to_O365'),
        lessThan(1),
        reason: 'a selected legend must filter the plot, not just the strip',
      );
      expect(markerOpacity(tester, 'All'), 1);
    });
  });

  group('line chart log axis', () {
    final DocsSection section = sectionOf(
      'charts-linechart--line-chart-log-axis-example',
    );

    testWidgets('each scale radio reshapes its own axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(chartPainter(tester).props.xScaleType, FluentAxisScaleType.log);
      final List<String> logX = chartPainter(tester).xAxis.tickLabels;
      final List<String> logY = chartPainter(tester).yAxisPrimary.tickLabels;

      // The two groups are declared xScaleType then yScaleType, so the first
      // 'default' belongs to x. A radio wired to the wrong group would move the
      // other axis's ticks and this pair of assertions is what catches it.
      await mouseClick(tester, find.text('default').first);
      expect(chartPainter(tester).props.xScaleType, FluentAxisScaleType.auto);
      expect(chartPainter(tester).xAxis.tickLabels, isNot(logX));
      expect(chartPainter(tester).yAxisPrimary.tickLabels, logY);

      await tapAndSettle(tester, find.text('default').last, what: 'yScaleType');
      expect(chartPainter(tester).props.yScaleType, FluentAxisScaleType.auto);
      expect(chartPainter(tester).yAxisPrimary.tickLabels, isNot(logY));

      await tapAndSettle(tester, find.text('log').first, what: 'xScaleType');
      expect(chartPainter(tester).props.xScaleType, FluentAxisScaleType.log);
      expect(chartPainter(tester).xAxis.tickLabels, logX);
    });

    testWidgets('the size readouts follow their sliders', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('700'), findsOneWidget);

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('700'), findsNothing);
      // The readout and the chart must agree: a label bound to the state while
      // the chart kept a stale width would show exactly this pair disagreeing.
      expect(tester.getSize(find.byType(FluentLineChart)).width, 1000);
    });
  });

  group('line chart events', () {
    testWidgets('the three events on one date merge into one label', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-linechart--line-chart-events'),
      );

      final FluentEventAnnotationPainter band =
          paintersOf<FluentEventAnnotationPainter>(tester).single;
      // Events 1-3 share 2020-03-04, so `eventAnnotationMergedLabel` speaks for
      // them; 4 and 5 stand alone. The rules are deduplicated by date
      // (`EventAnnotation.tsx:33`) while the labels are not, which is what makes
      // three rules the right count for five events.
      expect(band.labels.map((FluentEventLabel label) => label.text), <String>[
        '3 events',
        'event 4',
        'event 5',
      ]);
      expect(band.rules, hasLength(3));
    });

    testWidgets('the currency tick format reaches the y axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-linechart--line-chart-events'),
      );
      final FluentCartesianChartPainter painter = chartPainter(tester);
      final String Function(double) format = painter.props.yAxisTickFormat!;

      // The demo hands the chart d3's `format('$,')` for its y ticks, so the
      // labels the axis painted have to be that formatter's own output. Anything
      // else means the axis fell back to the default numeric ramp and the prop
      // is decoration.
      expect(
        painter.yAxisPrimary.tickLabels,
        painter.yAxisPrimary.tickValues
            .map((Object value) => format((value as num).toDouble()))
            .toList(),
      );
    });
  });

  group('line chart annotations', () {
    testWidgets('every annotation box lands with its text', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-linechart--line-chart-annotations-example'),
      );

      final String rendered = textSnapshot(tester);
      // One per coordinate kind the section demonstrates: data, relative and
      // pixel. A coordinate resolver that failed would drop its box entirely
      // rather than misplace it.
      for (final String text in <String>[
        'Launch day',
        'Pricing experiment',
        'Stretch goal',
        'Note:',
      ]) {
        expect(rendered, contains(text));
      }
      expect(
        find.byType(FluentChartAnnotationLayer),
        findsOneWidget,
        reason: 'the annotations must reach the chart, not a sibling stack',
      );
    });
  });

  group('every section', () {
    testWidgets('the width slider resizes every chart', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Size before = tester.getSize(find.byType(FluentLineChart));

        await dropSliderAt(tester, sliderNamed('Change Width'), 1);
        final Size after = tester.getSize(find.byType(FluentLineChart));
        expect(
          after.width,
          greaterThan(before.width),
          reason: '${section.id}: the width slider moved nothing',
        );
        expect(
          chartPainter(tester).layout.size.width,
          greaterThan(before.width - 100),
          reason: '${section.id}: the chart did not re-solve into its new box',
        );
        await expectCleanTeardown(tester, section.id);
      }
    });

    testWidgets('every multiple-shapes switch reaches the marks', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Finder toggle = find.byWidgetPredicate(
          (Widget widget) =>
              widget is FluentSwitch &&
              (widget.label! as Text).data!.toLowerCase().contains('shapes'),
        );
        if (toggle.evaluate().isEmpty) continue;

        await tapAndSettle(tester, toggle, what: '${section.id} shapes switch');
        expect(
          lineDelegate(tester).allowMultipleShapesForPoints,
          isTrue,
          reason: '${section.id}: the switch never reached the chart',
        );
        await tapAndSettle(tester, toggle, what: '${section.id} shapes switch');
        expect(lineDelegate(tester).allowMultipleShapesForPoints, isFalse);
      }
    });

    testWidgets('every axis-titles switch re-solves the margins', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Finder toggle = find.byWidgetPredicate(
          (Widget widget) =>
              widget is FluentSwitch &&
              (widget.label! as Text).data!.toLowerCase().contains(
                'axis titles',
              ),
        );
        if (toggle.evaluate().isEmpty) continue;

        final Rect titled = chartPainter(tester).layout.plotRect;
        await tapAndSettle(tester, toggle, what: '${section.id} titles switch');
        expect(
          chartPainter(tester).layout.plotRect.width,
          greaterThan(titled.width),
          reason: '${section.id}: hiding the titles freed no margin',
        );
      }
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

/// The one cartesian painter in the tree.
///
/// Everything a cartesian chart draws — axes, gridlines, titles, marks — is one
/// [CustomPaint], so the painter's fields are the only readable account of what
/// reached the screen.
FluentCartesianChartPainter chartPainter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).single;

/// The line chart's series delegate, as the shell handed it to the painter.
FluentLineChartDelegate lineDelegate(WidgetTester tester) =>
    chartPainter(tester).delegate as FluentLineChartDelegate;

/// The child context the shell built for this frame's paint.
///
/// [FluentLineChartDelegate.markersFor] takes the scales rather than reading
/// them, so a test that wants the marks has to rebuild the same context from the
/// painter's own geometry.
FluentCartesianChildContext childContext(FluentCartesianChartPainter painter) =>
    FluentCartesianChildContext(
      xScale: painter.xAxis.scale,
      yScalePrimary: painter.yAxisPrimary.scale,
      yScaleSecondary: painter.yAxisSecondary?.scale,
      containerWidth: painter.layout.size.width,
      containerHeight: painter.layout.size.height,
    );

/// The distinct marker shapes currently on the plot.
///
/// `null` is a plain circle — a one-point series always draws one — and an int
/// is an index into the eight `_getPointPath` shapes.
Set<int?> shapeIndexes(WidgetTester tester) => lineDelegate(tester)
    .markersFor(childContext(chartPainter(tester)))
    .map((FluentLineMark mark) => mark.shapeIndex)
    .toSet();

/// Where the [point]-th mark of series [series] was painted, in global
/// coordinates.
Offset markCentre(
  WidgetTester tester, {
  required int series,
  required int point,
}) {
  final FluentCartesianChartPainter painter = chartPainter(tester);
  final FluentLineMark mark = lineDelegate(tester)
      .markersFor(childContext(painter))
      .firstWhere(
        (FluentLineMark mark) =>
            mark.seriesIndex == series && mark.pointIndex == point,
      );
  return tester.getTopLeft(plotFinder()) + mark.centre;
}

/// The [CustomPaint] the cartesian painter is mounted on.
Finder plotFinder() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
);

/// The opacity every mark of [legend] is painted at.
///
/// One number stands for the whole filter: `markerOpacityFor` is what
/// `_legendHighlighted` (`LineChart.tsx:1817`) feeds, and the segments read the
/// same predicate.
double markerOpacity(WidgetTester tester, String legend) =>
    lineDelegate(tester).markerOpacityFor(legend);

/// The legend row whose label reads [title].
FluentChartLegendRow legendRow(WidgetTester tester, String title) =>
    tester.widget<FluentChartLegendRow>(
      find.widgetWithText(FluentChartLegendRow, title),
    );

/// The slider a demo labelled [semanticLabel].
///
/// Both sliders on every one of these demos are unlabelled visually — the text
/// beside them is a sibling `Text` — so the accessible name is the only thing
/// that tells width from height.
Finder sliderNamed(String semanticLabel) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSlider && widget.semanticLabel == semanticLabel,
);

/// The switch whose own label contains [fragment], case-insensitively.
///
/// A Fluent switch shows its state *in* its label — "Show axis titles" becomes
/// "Hide axis titles" — so a finder for the full string would stop matching the
/// moment the switch is flipped.
Finder switchLabelled(String fragment) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSwitch &&
      (widget.label! as Text).data!.toLowerCase().contains(
        fragment.toLowerCase(),
      ),
);

/// The instant every x tick sits on, in epoch milliseconds.
///
/// Comparing the [DateTime]s themselves would be weaker than it looks: Dart's
/// `==` counts the UTC flag, so two ticks a zone apart and two ticks on the same
/// instant both come out unequal. The epoch reading is the placement.
List<int> tickInstants(WidgetTester tester) => <int>[
  for (final Object tick in chartPainter(tester).xAxis.tickValues)
    (tick as DateTime).millisecondsSinceEpoch,
];

/// The date line of the popover for the fourth point of the first line.
///
/// One fixed point, hovered and released, so the two halves of a knob test read
/// the same instant: the roving focus is not usable for that here, because the
/// stop order follows the hit regions and those move with the domain.
Future<String> popoverDateOfFourthPoint(WidgetTester tester) async {
  final TestGesture mouse = await hoverAt(
    tester,
    markCentre(tester, series: 0, point: 3),
    what: 'the fourth point of the first line',
  );
  final String date = popoverTexts(tester).first;
  await mouseAway(tester, mouse);
  return date;
}

/// Every string the open popover is showing.
List<String> popoverTexts(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(FluentChartPopover),
        matching: find.byType(Text),
      ),
    )
    .map((Text text) => text.data ?? '')
    .toList();

/// Walks the plot's roving focus [count] stops to the right.
///
/// The chart is one focus stop with an arrow-navigation group inside it
/// (`CartesianChart.tsx:87`), and a focused mark opens the same popover a hover
/// does — which is what makes the popover reachable without guessing at pixels.
Future<void> sendArrows(WidgetTester tester, int count) async {
  for (int i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await settle(tester);
  }
}
