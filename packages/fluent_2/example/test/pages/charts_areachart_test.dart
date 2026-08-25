import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// AreaChart's page is eight demos, and only the first two carry knobs beyond
/// the size sliders every section shares. Everything a cartesian chart draws
/// goes onto one [CustomPaint], so each assertion below reads the painter the
/// shell built — its layout, its axes and its delegate — rather than the widgets
/// around it: a knob that moved nothing would leave every `Text` in the demo
/// exactly where it was.
void main() {
  const String page = 'charts-areachart';

  group('area chart basic', () {
    final DocsSection section = sectionOf('charts-areachart--area-chart-basic');

    testWidgets('the size sliders resize the chart and round trip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentAreaChart)),
        const Size(700, 300),
      );

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      expect(tester.getSize(find.byType(FluentAreaChart)).width, 1000);
      // The box alone proves nothing: the plot has to be re-solved into it or
      // the chart is a 700-wide drawing sitting in a 1000-wide hole.
      expect(chartPainter(tester).layout.size.width, 1000);

      await dropSliderAt(tester, sliderNamed('Change Height'), 1);
      expect(tester.getSize(find.byType(FluentAreaChart)).height, 1000);

      await dropSliderAt(tester, sliderNamed('Change Width'), 0);
      expect(tester.getSize(find.byType(FluentAreaChart)).width, 200);
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = sliderNamed('Change Width');
      await tester.ensureVisible(slider);
      await settle(tester);

      // A press with travel rather than a synthetic tap: the section sits in a
      // scroll view, and a mouse that still counted as a drag device would have
      // this click stolen by the scroller before the rail ever saw it.
      final Rect rail = tester.getRect(slider);
      await mouseClickAt(
        tester,
        Offset(rail.right - 1, rail.center.dy),
        what: 'the width rail at its far end',
      );
      expect(
        tester.getSize(find.byType(FluentAreaChart)).width,
        greaterThan(700),
      );
    });

    testWidgets('the axis-titles switch gives the plot its margin back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder toggle = switchLabelled('axis titles');
      final Rect titled = chartPainter(tester).layout.plotRect;

      await tapAndSettle(tester, toggle, what: 'the axis-titles switch');
      final Rect bare = chartPainter(tester).layout.plotRect;
      // `_applyTitleMargins` (`CartesianChart.tsx:684-696`) buys each title its
      // own margin, so dropping both widens and heightens the plot. The titles
      // themselves are painted into the canvas and cannot be found as text.
      expect(bare.width, greaterThan(titled.width));
      expect(bare.height, greaterThan(titled.height));

      await tapAndSettle(tester, toggle, what: 'the axis-titles switch');
      expect(chartPainter(tester).layout.plotRect, titled);
    });

    testWidgets('the chart-mode switch unstacks the layers and rescales y', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder toggle = switchLabelled('chart mode');
      final List<String> stacked = chartPainter(tester).yAxisPrimary.tickLabels;
      final double stackedMax = areaDelegate(tester).dataSet.maxOfYVal;

      await tapAndSettle(tester, toggle, what: 'the chart-mode switch');
      expect(areaDelegate(tester).mode, FluentAreaChartMode.toZeroY);
      // Three series that stacked to 72k rest on zero one at a time, so the
      // domain the axis is solved over collapses to the tallest single series.
      // A mode that reached the delegate without rebuilding the dataset would
      // leave this ceiling exactly where it was.
      expect(areaDelegate(tester).dataSet.maxOfYVal, lessThan(stackedMax));
      expect(chartPainter(tester).yAxisPrimary.tickLabels, isNot(stacked));

      await tapAndSettle(tester, toggle, what: 'the chart-mode switch');
      expect(areaDelegate(tester).mode, FluentAreaChartMode.toNextY);
      expect(chartPainter(tester).yAxisPrimary.tickLabels, stacked);
    });

    testWidgets('the multi-select switch decides how many legends survive', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Single is the demo's default: a second pick replaces the first
      // (`Legends.tsx:238`).
      await tapAndSettle(tester, legendNamed('Legend1'), what: 'legend 1');
      await tapAndSettle(tester, legendNamed('Legend2'), what: 'legend 2');
      expect(areaDelegate(tester).selectedLegends, <String>['legend2']);
      expect(legendRow(tester, 'Legend1').dimmed, isTrue);

      // Unmounted before the second half rather than re-pumped over the top of
      // it: `pumpSection` rebuilds the same widget in the same slot, so the
      // demo's State — the selection included — would survive into a run that
      // is supposed to start clean.
      await expectCleanTeardown(tester, section.id);
      await pumpSection(tester, section);
      await tapAndSettle(
        tester,
        switchLabelled('multiple legends'),
        what: 'the multi-select switch',
      );
      await tapAndSettle(tester, legendNamed('Legend1'), what: 'legend 1');
      await tapAndSettle(tester, legendNamed('Legend2'), what: 'legend 2');
      expect(
        areaDelegate(tester).selectedLegends,
        <String>['legend1', 'legend2'],
        reason: 'multi-select must accumulate, not replace',
      );
      expect(legendRow(tester, 'Legend3').dimmed, isTrue);

      // "All selected" is canonicalised back to "none selected"
      // (`Legends.tsx:225-227`), which is this demo's way back to an unfiltered
      // chart.
      await tapAndSettle(tester, legendNamed('Legend3'), what: 'legend 3');
      expect(areaDelegate(tester).selectedLegends, isEmpty);
      expect(legendRow(tester, 'Legend1').dimmed, isFalse);
    });

    testWidgets('the example radio commits both of its options', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<String>);
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'basicExample',
      );

      // No chart change is demanded here on purpose: the demo's own comment
      // records that upstream's handler re-sets the flag it already holds, so
      // both options render the basic example. What must still work is the
      // selection itself — a radio group that refused the second option would be
      // a defect this page could hide behind that note.
      await mouseClick(tester, find.text('Custom Callout Example'));
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'calloutExample',
      );

      await tapAndSettle(tester, find.text('Basic Example'), what: 'the radio');
      expect(
        tester.widget<FluentRadioGroup<String>>(group).value,
        'basicExample',
      );
    });

    testWidgets('clicking a legend dims every other area', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double lit = areaDelegate(tester).fillOpacityFor('legend1');

      await mouseClick(tester, legendNamed('Legend1'));
      expect(legendRow(tester, 'Legend1').selected, isTrue);
      // `_getOpacity` (`AreaChart.tsx:619-626`) is what turns a selection into a
      // filter, so the fill of every unselected series has to fall away with it.
      expect(areaDelegate(tester).fillOpacityFor('legend1'), lit);
      expect(
        areaDelegate(tester).fillOpacityFor('legend2'),
        lessThan(lit),
        reason: 'a selected legend must filter the plot, not just the strip',
      );

      await mouseClick(tester, legendNamed('Legend1'));
      expect(areaDelegate(tester).fillOpacityFor('legend2'), lit);
    });

    testWidgets('a real pointer over the plot opens the stacked popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      // AreaChart resolves its hover by inverting the pointer's x and bisecting
      // series 0 (`AreaChart.tsx:185-192`), so the cursor has to be over a real
      // x — the centre of the widget is not one.
      final TestGesture mouse = await hoverAt(
        tester,
        pointCentre(tester, 5),
        what: 'a data point',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      // One reading per series at the hovered x, which is what a stacked area
      // chart's callout is for.
      for (final String legend in <String>['legend1', 'legend2', 'legend3']) {
        expect(popoverTexts(tester), contains(legend));
      }
      expect(
        tester
            .state<FluentAreaChartState>(find.byType(FluentAreaChart))
            .nearestX,
        isNotNull,
      );

      // `_handleChartMouseLeave` (`:279-289`) resets everything, so lifting the
      // pointer must take the popover with it.
      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
      expect(
        tester
            .state<FluentAreaChartState>(find.byType(FluentAreaChart))
            .nearestX,
        isNull,
      );
    });
  });

  group('area chart negative', () {
    final DocsSection section = sectionOf(
      'charts-areachart--area-chart-negative',
    );

    testWidgets('the axis-titles switch re-solves the margins', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect titled = chartPainter(tester).layout.plotRect;

      await tapAndSettle(
        tester,
        switchLabelled('axis titles'),
        what: 'the axis-titles switch',
      );
      expect(
        chartPainter(tester).layout.plotRect.width,
        greaterThan(titled.width),
      );
      await tapAndSettle(
        tester,
        switchLabelled('axis titles'),
        what: 'the axis-titles switch',
      );
      expect(chartPainter(tester).layout.plotRect, titled);
    });

    testWidgets('the y axis spans both sides of zero', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<double> ticks = chartPainter(tester).yAxisPrimary.tickValues
          .map((Object value) => (value as num).toDouble())
          .toList();

      // The section's whole subject: a series that dips below the baseline has
      // to move the floor down rather than clip.
      expect(ticks.any((double tick) => tick < 0), isTrue);
      expect(ticks.any((double tick) => tick > 0), isTrue);
    });
  });

  group('area chart secondary y axis', () {
    testWidgets('both scales are solved and titled', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('charts-areachart--area-chart-secondary-y-axis'),
      );
      final FluentCartesianChartPainter painter = chartPainter(tester);

      expect(
        painter.yAxisSecondary,
        isNotNull,
        reason: 'secondaryYScaleOptions must produce a second axis',
      );
      expect(painter.yAxisSecondary!.tickLabels, isNotEmpty);
      expect(painter.props.secondaryYAxisTitle, isNotNull);
      // The secondary title takes its own right margin
      // (`CartesianChart.tsx:690-694`), so the plot cannot reach the right edge.
      expect(
        painter.layout.plotRect.right,
        lessThan(painter.layout.size.width - 40),
      );
    });
  });

  group('every section', () {
    testWidgets('the width slider resizes every chart', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Size before = tester.getSize(find.byType(FluentAreaChart));

        await dropSliderAt(tester, sliderNamed('Change Width'), 1);
        expect(
          tester.getSize(find.byType(FluentAreaChart)).width,
          greaterThan(before.width),
          reason: '${section.id}: the width slider moved nothing',
        );
        expect(
          chartPainter(tester).layout.size.width,
          greaterThan(before.width),
          reason: '${section.id}: the chart did not re-solve into its new box',
        );
        await expectCleanTeardown(tester, section.id);
      }
    });

    testWidgets('the height slider resizes every chart', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Size before = tester.getSize(find.byType(FluentAreaChart));

        await dropSliderAt(tester, sliderNamed('Change Height'), 1);
        expect(
          tester.getSize(find.byType(FluentAreaChart)).height,
          greaterThan(before.height),
          reason: '${section.id}: the height slider moved nothing',
        );
        await expectCleanTeardown(tester, section.id);
      }
    });

    testWidgets('a section that asks for a tick format gets one', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final FluentCartesianChartPainter painter = chartPainter(tester);
        final String Function(double)? format = painter.props.yAxisTickFormat;
        if (format == null) continue;

        // Four of these demos exist to show money on the y axis — that is what
        // `d3.format('$,')` is doing in each of them. The labels the axis
        // actually painted have to be the formatter's own output, or the demo is
        // showing the default numeric ramp and the prop is decoration.
        expect(
          painter.yAxisPrimary.tickLabels,
          painter.yAxisPrimary.tickValues
              .map((Object value) => format((value as num).toDouble()))
              .toList(),
          reason: '${section.id}: yAxisTickFormat never reached the y axis',
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
/// Axes, gridlines, titles and every filled layer are a single [CustomPaint], so
/// the painter's fields are the only readable account of what reached the
/// screen.
FluentCartesianChartPainter chartPainter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).single;

/// The area chart's series delegate, as the shell handed it to the painter.
FluentAreaChartDelegate areaDelegate(WidgetTester tester) =>
    chartPainter(tester).delegate as FluentAreaChartDelegate;

/// Where the [index]-th hit region of the plot sits, in global coordinates.
///
/// A chart is one hit target: the popover belongs to the point under the
/// cursor, and the only description of where a point landed is the geometry the
/// delegate just painted with.
Offset pointCentre(WidgetTester tester, int index) {
  final FluentCartesianChartPainter painter = chartPainter(tester);
  final FluentChartHitRegion region = painter.delegate.buildHitRegions(
    FluentCartesianChildContext(
      xScale: painter.xAxis.scale,
      yScalePrimary: painter.yAxisPrimary.scale,
      yScaleSecondary: painter.yAxisSecondary?.scale,
      containerWidth: painter.layout.size.width,
      containerHeight: painter.layout.size.height,
    ),
    painter.layout,
  )[index];
  return tester.getTopLeft(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is CustomPaint &&
              widget.painter is FluentCartesianChartPainter,
        ),
      ) +
      region.bounds.center;
}

/// The legend row whose label reads [title].
Finder legendNamed(String title) =>
    find.widgetWithText(FluentChartLegendRow, title);

/// The legend row widget whose label reads [title].
FluentChartLegendRow legendRow(WidgetTester tester, String title) =>
    tester.widget<FluentChartLegendRow>(legendNamed(title));

/// The slider a demo labelled [semanticLabel].
///
/// Both sliders on every one of these demos are visually unlabelled — the text
/// beside them is a sibling `Text` — so the accessible name is the only thing
/// that tells width from height.
Finder sliderNamed(String semanticLabel) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSlider && widget.semanticLabel == semanticLabel,
);

/// The switch whose own label contains [fragment], case-insensitively.
///
/// A Fluent switch shows its state *in* its label — "Show Axis titles" becomes
/// "Hide Axis titles" — so a finder for the whole string would stop matching the
/// moment the switch is flipped.
Finder switchLabelled(String fragment) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSwitch &&
      (widget.label! as Text).data!.toLowerCase().contains(
        fragment.toLowerCase(),
      ),
);

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
