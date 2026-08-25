import 'dart:math' as math;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// DonutChart's page is six donuts, only one of which carries knobs — Dynamic,
/// with two checkboxes and two buttons. The other five have to prove themselves
/// through the affordances every donut has: an arc that opens a popover under
/// the pointer, a legend row that dims everything it did not select, and a hole
/// whose value follows that selection.
///
/// Nothing here reads a `Text` where the answer lives on the canvas. A donut
/// paints its arcs, its arc labels and its focus ring into one [CustomPaint],
/// so [FluentDonutChartPainter] — its opacities, its labels and its solved
/// layout — is the only honest description of what reached the screen.
void main() {
  const String page = 'charts-donutchart';

  group('donut chart basic', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-basic',
    );

    testWidgets('a legend row dims the other arc and rewrites the hole', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(donutPainter(tester).opacities, <double>[1, 1]);
      expect(find.text('35,000'), findsOneWidget);

      // A real mouse, not a tap: the legend row hangs its highlight on a
      // MouseRegion wrapped around the pressable, and a synthetic tap
      // synthesises no enter at all — a row that only responded to hover would
      // pass a tap-driven suite and be dead under a cursor.
      await mouseClick(tester, find.text('First'));
      expect(
        donutPainter(tester).opacities,
        <double>[1, 0.1],
        reason: 'selecting one legend must dim every arc it did not select',
      );
      // `valueInsideDonut` is the literal 35000 until a selection narrows it,
      // and then it is the selected slice's own value — so the hole is the one
      // place a legend press is legible without a screen reader.
      expect(find.text('20,000'), findsOneWidget);
      expect(find.text('35,000'), findsNothing);

      await mouseClick(tester, find.text('First'));
      expect(donutPainter(tester).opacities, <double>[1, 1]);
      expect(find.text('35,000'), findsOneWidget);
    });

    testWidgets('hovering an arc opens that slice\'s popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      TestGesture mouse = await hoverAt(
        tester,
        arcPoint(tester, 0),
        what: 'the first arc',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      // The callout overrides win over the legend and the raw datum, which is
      // the whole reason this section sets `xAxisCalloutData`.
      expect(find.text('2020/04/30'), findsOneWidget);
      expect(find.text('20000'), findsOneWidget);
      await mouseAway(tester, mouse);
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'leaving the plot must close the popover',
      );

      mouse = await hoverAt(
        tester,
        arcPoint(tester, 1),
        what: 'the second arc',
      );
      expect(find.text('2020/04/20'), findsOneWidget);
      expect(find.text('35000'), findsOneWidget);
      await mouseAway(tester, mouse);
    });
  });

  group('donut chart custom accessibility', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-custom-accessibility',
    );

    testWidgets('each arc announces its own callout label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The point of the section: a datum's `callOutSemantics` replaces the
      // generated "legend, value." string rather than being appended to it.
      expect(
        find.bySemanticsLabel('Pia chart 1 of 2 2020/04/30'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Pia chart 2 of 2 2020/04/20'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('first, 20000.'),
        findsNothing,
        reason: 'the generated label must be replaced, not doubled up',
      );
    });

    testWidgets('the hole follows a legend selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('39,000'), findsOneWidget);

      await mouseClick(tester, find.text('First'));
      expect(donutPainter(tester).opacities, <double>[1, 0.1]);
      expect(find.text('20,000'), findsOneWidget);

      await mouseClick(tester, find.text('First'));
      expect(find.text('39,000'), findsOneWidget);
    });
  });

  group('donut chart dynamic', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-dynamic',
    );

    testWidgets(
      'the hide-labels checkbox drops the labels and widens the hole',
      (WidgetTester tester) async {
        await pumpSection(tester, section);
        expect(donutPainter(tester).labels, hasLength(4));
        expect(donutPainter(tester).layout.innerRadius, 35);

        await mouseClick(tester, hideLabelsCheckbox);
        expect(
          donutPainter(tester).labels,
          isEmpty,
          reason: 'hideLabels must reach the painter, not just the checkbox',
        );
        // The demo's own promise, spelled out in the label: the inner radius
        // moves with the checkbox so the ring keeps its width.
        expect(donutPainter(tester).layout.innerRadius, 55);

        await mouseClick(tester, hideLabelsCheckbox);
        expect(donutPainter(tester).labels, hasLength(4));
        expect(donutPainter(tester).layout.innerRadius, 35);
      },
    );

    testWidgets('the percentage checkbox reformats every arc label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(labelTexts(tester), <String>['40', '20', '30', '10']);

      await tapAndSettle(tester, percentCheckbox, what: 'the percent checkbox');
      expect(
        labelTexts(tester),
        <String>['40%', '20%', '30%', '10%'],
        reason: 'the labels are the only place showLabelsInPercent shows',
      );

      await tapAndSettle(tester, percentCheckbox, what: 'the percent checkbox');
      expect(labelTexts(tester), <String>['40', '20', '30', '10']);
    });

    testWidgets('Change data redraws the arcs and announces it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<double> before = sliceValues(tester);
      final List<Color> colours = donutPainter(tester).fills;

      await tapAndSettle(tester, find.text('Change data'));
      expect(
        sliceValues(tester),
        isNot(before),
        reason: 'the button re-rolls every value, so no arc can keep its sweep',
      );
      // The button is data-only upstream, and the palette is pinned per index,
      // so a re-roll that also repainted would be the wrong button.
      expect(donutPainter(tester).fills, colours);
      expect(
        find.bySemanticsLabel('Donut chart data changed'),
        findsOneWidget,
        reason: 'the live region is the only thing a screen reader gets',
      );
    });

    testWidgets('Change colors repaints without moving an arc', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<double> before = sliceValues(tester);
      final List<Color> colours = donutPainter(tester).fills;

      await tapAndSettle(tester, find.text('Change colors'));
      // Each slice re-rolls out of a disjoint band of the palette — slice 0
      // from colours 3..7, slice 1 from 8..11 and so on — so its own starting
      // colour is not a possible outcome and every fill must have moved.
      expect(donutPainter(tester).fills, isNot(colours));
      expect(sliceValues(tester), before);
      expect(
        find.bySemanticsLabel('Donut chart colors changed'),
        findsOneWidget,
      );
    });
  });

  group('donut chart custom callout', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-custom-callout',
    );

    testWidgets('the override switch flips and the built-in popover survives', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder toggle = find.byType(FluentSwitch);

      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isTrue);

      // `FluentDonutChart` owns its popover and exposes neither
      // `calloutPropsPerDataPoint` nor `onRenderCalloutPerDataPoint`, so the
      // section documents this switch as live-but-inert. What must NOT happen
      // is the built-in popover going away with it, which is the only failure
      // mode a reader of this demo could actually be misled by.
      final TestGesture mouse = await hoverAt(
        tester,
        arcPoint(tester, 0),
        what: 'the first arc',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(find.text('2020/04/30'), findsOneWidget);
      await mouseAway(tester, mouse);

      await mouseClick(tester, toggle);
      expect(tester.widget<FluentSwitch>(toggle).checked, isFalse);
    });
  });

  group('donut chart styled', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-styled',
    );

    testWidgets('the styled frame is an ellipse around a working donut', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final BoxDecoration frame =
          tester.widget<Container>(find.byType(Container).first).decoration!
              as BoxDecoration;
      expect(frame.border, isNotNull);
      // The radius is solved from the incoming width, so it is an ellipse and
      // not the circle `BoxShape.circle` would inscribe on the short side.
      expect(
        frame.borderRadius,
        BorderRadius.all(
          Radius.elliptical(tester.view.physicalSize.width / 2, 160),
        ),
      );

      expect(find.text('39,000'), findsOneWidget);
      await mouseClick(tester, find.text('First'));
      expect(
        donutPainter(tester).opacities,
        <double>[1, 0.1],
        reason: 'the frame must not swallow the legend presses inside it',
      );
      expect(find.text('20,000'), findsOneWidget);
    });
  });

  group('donut chart responsive', () {
    final DocsSection section = sectionOf(
      'charts-donutchart--donut-chart-responsive',
    );

    testWidgets('the donut re-centres on whatever width it is handed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(donutPainter(tester).layout.slices, hasLength(10));
      expect(donutPainter(tester).layout.centre.dx, 800);

      // The section's whole claim: no width prop, so the plot is exactly the
      // box. A donut that had frozen its geometry at first layout would keep
      // the old centre here.
      await pumpSection(tester, section, size: const Size(700, 1400));
      expect(donutPainter(tester).layout.centre.dx, 350);
      expect(donutPainter(tester).layout.slices, hasLength(10));
    });

    testWidgets('the legend overflow trigger opens the rows it hid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Ten legends do not fit, so five are folded behind the trigger — and a
      // folded legend that could not be reached would make half the series
      // unselectable.
      expect(find.text('Tenth'), findsNothing);

      await openOverlay(tester, find.textContaining('more'));
      expect(find.text('Tenth'), findsOneWidget);
      expect(find.text('Sixth'), findsOneWidget);
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

/// The one donut painter in the tree.
FluentDonutChartPainter donutPainter(WidgetTester tester) =>
    paintersOf<FluentDonutChartPainter>(tester).first;

/// Every arc label, in slice order.
List<String> labelTexts(WidgetTester tester) => donutPainter(
  tester,
).labels.map((FluentDonutArcLabel label) => label.text).toList();

/// Every slice's laid-out value, in slice order.
List<double> sliceValues(WidgetTester tester) => donutPainter(
  tester,
).layout.slices.map((FluentDonutSlice slice) => slice.value).toList();

/// A screen point half way through the ring of slice [index].
///
/// The arcs are drawn, not laid out: the `Positioned` boxes over them are the
/// arcs' bounding rects and carry no gesture of their own, so the pointer has
/// to land inside the real path or the chart's own hit test rejects it. d3's
/// angles are zero at twelve o'clock and grow clockwise, which is why the sine
/// drives x and the cosine drives y.
Offset arcPoint(WidgetTester tester, int index) {
  final FluentDonutChartPainter painter = donutPainter(tester);
  final FluentDonutSlice slice = painter.layout.slices[index];
  final double angle = (slice.startAngle + slice.endAngle) / 2;
  final double radius =
      (painter.layout.innerRadius + painter.layout.outerRadius) / 2;
  final Offset local =
      painter.layout.centre +
      Offset(math.sin(angle) * radius, -math.cos(angle) * radius);
  return tester.getTopLeft(plotOf<FluentDonutChartPainter>()) + local;
}

/// The Dynamic section's first checkbox, found by its sentence rather than its
/// position so a reordered demo fails loudly instead of testing the other one.
Finder get hideLabelsCheckbox => find.ancestor(
  of: find.textContaining('Hide labels'),
  matching: find.byType(FluentCheckbox),
);

/// The Dynamic section's second checkbox.
Finder get percentCheckbox => find.ancestor(
  of: find.text('Show labels in percentage format'),
  matching: find.byType(FluentCheckbox),
);
