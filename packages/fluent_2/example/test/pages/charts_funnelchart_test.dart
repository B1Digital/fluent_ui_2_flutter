import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// FunnelChart's page is two funnels — Basic and Stacked — carrying the same
/// five knobs each: two size sliders, a Hide Legend switch, a multi-select
/// switch and an orientation radio group.
///
/// Every trapezium is painted into one [CustomPaint], so the geometry that
/// answers "did the orientation actually turn?" and the opacity that answers
/// "did the legend dim anything?" both live on [FluentFunnelChartPainter] and
/// nowhere in the widget tree.
void main() {
  const String page = 'charts-funnelchart';

  group('funnel chart basic', () {
    final DocsSection section = sectionOf(
      'charts-funnelchart--funnel-chart-basic',
    );

    testWidgets('the orientation radio turns the funnel on its side', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect wide = firstSegment(tester);
      expect(
        wide.height,
        greaterThan(wide.width),
        reason: 'horizontal stages run left to right, so each one is a column',
      );

      await mouseClick(tester, find.text('Vertical'));
      expect(orientation(tester), FluentFunnelOrientation.vertical);
      final Rect tall = firstSegment(tester);
      expect(
        tall.width,
        greaterThan(tall.height),
        reason: 'vertical stages stack, so the widest one is a band',
      );

      await mouseClick(tester, find.text('Horizontal'));
      expect(orientation(tester), FluentFunnelOrientation.horizontal);
      expect(firstSegment(tester), wide);
    });

    testWidgets('Hide Legend takes the chart title with it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartLegendRow), findsNWidgets(4));
      expect(find.text('Basic Funnel Chart'), findsOneWidget);

      await tapAndSettle(tester, find.text('Hide Legend'));
      expect(find.byType(FluentChartLegendRow), findsNothing);
      // Not a slip in the test: `FunnelChart.tsx:490` gates the title on the
      // same flag as the legend and the port reproduces it, tagged `parity:`.
      // Asserting the title stays would be asserting against the port's own
      // documented behaviour.
      expect(find.text('Basic Funnel Chart'), findsNothing);

      await tapAndSettle(tester, find.text('Hide Legend'));
      expect(find.byType(FluentChartLegendRow), findsNWidgets(4));
      expect(find.text('Basic Funnel Chart'), findsOneWidget);
    });

    testWidgets('the size sliders resize the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentFunnelChart)),
        const Size(600, 500),
      );
      final Rect before = firstSegment(tester);

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      await dropSliderAt(tester, sliderNamed('Change Height'), 0);
      expect(
        tester.getSize(find.byType(FluentFunnelChart)),
        const Size(1000, 200),
        reason: 'both sliders run 200..1000, so the ends are exact',
      );
      // The box moving is not the point; the funnel re-solving inside it is.
      expect(firstSegment(tester).width, greaterThan(before.width));
      expect(firstSegment(tester).height, lessThan(before.height));
    });

    testWidgets('Multiple Legend Selection keeps a second stage lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(opacities(tester), <double>[1, 1, 1, 1]);

      await mouseClick(tester, find.text('Visitors'));
      expect(opacities(tester), <double>[1, 0.1, 0.1, 0.1]);
      await mouseClick(tester, find.text('Signups'));
      expect(
        opacities(tester),
        <double>[0.1, 1, 0.1, 0.1],
        reason: 'single select keeps only the last legend pressed',
      );

      await tapAndSettle(tester, find.text('Multiple Legend Selection'));
      await tapAndSettle(tester, find.text('Visitors'));
      expect(
        opacities(tester),
        <double>[1, 1, 0.1, 0.1],
        reason: 'multi select must let the second press join the first',
      );
    });

    testWidgets('hovering a segment opens its stage popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      final TestGesture mouse = await hoverAt(
        tester,
        segmentPoint(tester, 0),
        what: 'the Visitors stage',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(find.text('Visitors'), findsNWidgets(2));
      // Not '1,000': `formatter.ts:39` turns grouping on at |data| >= 10000,
      // and the port reproduces it (tick_format.dart:236). Asserting the comma
      // would be asserting against the port's own documented parity.
      expect(find.text('1000'), findsOneWidget);

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });
  });

  group('funnel chart stacked', () {
    final DocsSection section = sectionOf(
      'charts-funnelchart--funnel-chart-stacked',
    );

    testWidgets('the orientation radio turns the funnel on its side', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect wide = firstSegment(tester);

      await mouseClick(tester, find.text('Vertical'));
      expect(orientation(tester), FluentFunnelOrientation.vertical);
      expect(firstSegment(tester), isNot(wide));
      // Twelve sub-values, three stages: the count is the same either way, so
      // only the geometry can tell the two orientations apart.
      expect(opacities(tester), hasLength(12));

      await mouseClick(tester, find.text('Horizontal'));
      expect(firstSegment(tester), wide);
    });

    testWidgets('a legend row lights its category in every stage', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The legend of a stacked funnel is the category set, not the stages, so
      // one press has to reach one sub-value inside each of the three stages.
      expect(find.text('A'), findsOneWidget);

      await mouseClick(tester, find.text('A'));
      expect(opacities(tester), <double>[
        1, 0.1, 0.1, 0.1, //
        1, 0.1, 0.1, 0.1,
        1, 0.1, 0.1, 0.1,
      ]);

      await mouseClick(tester, find.text('A'));
      expect(opacities(tester), List<double>.filled(12, 1));
    });

    testWidgets('Multiple Legend Selection keeps a second category lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Multiple Legend Selection'));

      await tapAndSettle(tester, find.text('A'));
      await tapAndSettle(tester, find.text('B'));
      expect(opacities(tester), <double>[
        1, 1, 0.1, 0.1, //
        1, 1, 0.1, 0.1,
        1, 1, 0.1, 0.1,
      ]);
    });

    testWidgets('the size sliders resize the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentFunnelChart)),
        const Size(600, 500),
      );
      final Rect before = firstSegment(tester);

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      await dropSliderAt(tester, sliderNamed('Change Height'), 0);
      expect(
        tester.getSize(find.byType(FluentFunnelChart)),
        const Size(1000, 200),
      );
      // A stacked funnel scales every stage off the largest stage total, so a
      // new box has to re-solve all twelve sub-values and not just clip them.
      expect(firstSegment(tester).width, greaterThan(before.width));
      expect(firstSegment(tester).height, lessThan(before.height));
      expect(opacities(tester), hasLength(12));
    });

    testWidgets('Hide Legend takes the chart title with it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartLegendRow), findsNWidgets(4));
      expect(find.text('Stacked Funnel Chart'), findsOneWidget);

      await tapAndSettle(tester, find.text('Hide Legend'));
      expect(find.byType(FluentChartLegendRow), findsNothing);
      expect(find.text('Stacked Funnel Chart'), findsNothing);

      await tapAndSettle(tester, find.text('Hide Legend'));
      expect(find.text('Stacked Funnel Chart'), findsOneWidget);
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

/// The one funnel painter in the tree.
FluentFunnelChartPainter funnelPainter(WidgetTester tester) =>
    paintersOf<FluentFunnelChartPainter>(tester).first;

/// Every segment's opacity, in paint order — stage-major, sub-value-minor.
List<double> opacities(WidgetTester tester) => funnelPainter(
  tester,
).segments.map((FluentFunnelSegment segment) => segment.opacity).toList();

/// The bounding box of the widest stage, which is always the first one.
Rect firstSegment(WidgetTester tester) =>
    funnelPainter(tester).segments.first.geometry.path!.getBounds();

/// The orientation the demo's radio group currently holds.
FluentFunnelOrientation? orientation(WidgetTester tester) => tester
    .widget<FluentRadioGroup<FluentFunnelOrientation>>(
      find.byType(FluentRadioGroup<FluentFunnelOrientation>),
    )
    .value;

/// The slider whose accessible name is [label].
///
/// Both sliders sit in the same `Wrap` and are the same size, so an index would
/// quietly test the wrong one the day a control is inserted above them.
Finder sliderNamed(String label) => find.ancestor(
  of: find.bySemanticsLabel(label),
  matching: find.byType(FluentSlider),
);

/// A screen point inside segment [index].
///
/// The trapezia are painted and hit-tested against the painter's own paths, so
/// the centre of a segment's bounds is where the chart itself looks for it.
Offset segmentPoint(WidgetTester tester, int index) =>
    tester.getTopLeft(plotOf<FluentFunnelChartPainter>()) +
    funnelPainter(tester).segments[index].geometry.path!.getBounds().center;
