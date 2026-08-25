import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// GaugeChart's page is three gauges: Basic and Single Segment each carry three
/// sliders and a bank of toggles, and Responsive carries none and has to track
/// the box it is handed instead.
///
/// A gauge keeps almost nothing in the widget tree — the arc, the needle, the
/// two limit labels and the focus ring are all one [CustomPaint] — so the
/// assertions read [FluentGaugeChartPainter]: its needle rotation, its per-band
/// opacities, its limit strings and its arc paths.
void main() {
  const String page = 'charts-gaugechart';

  group('gauge chart basic', () {
    final DocsSection section = sectionOf(
      'charts-gaugechart--gauge-chart-basic',
    );

    testWidgets('the width slider stretches the gauge under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(tester.getSize(find.byType(FluentGaugeChart)).width, 252);
      // 252 is too narrow for three legends, so two of them start folded behind
      // the overflow trigger.
      expect(find.byType(FluentChartLegendRow), findsOneWidget);

      // Pressed with a real mouse at the far end of the rail rather than
      // tapped: `mouseClickAt` travels two pixels between press and release,
      // which is the drag slop a scroll view used to steal a slider press
      // inside, and the rail clamps anything past its end so the travel cannot
      // overshoot the maximum.
      final Rect rail = tester.getRect(sliderNamed('Change Width'));
      await mouseClickAt(
        tester,
        Offset(rail.right - 0.5, rail.center.dy),
        what: 'the width slider',
      );
      expect(find.text('1000'), findsOneWidget);
      expect(tester.getSize(find.byType(FluentGaugeChart)).width, 1000);
      expect(
        find.byType(FluentChartLegendRow),
        findsNWidgets(3),
        reason: 'a wider gauge must unfold the legends it had hidden',
      );

      await dropSliderAt(tester, sliderNamed('Change Width'), 0);
      expect(find.text('0'), findsWidgets);
      expect(
        tester.getSize(find.byType(FluentGaugeChart)).width,
        0,
        reason: 'the slider runs to zero, so the gauge has to survive zero',
      );
    });

    testWidgets('the height slider retunes the gauge geometry', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double before = gaugePainter(tester).layout.outerRadius;

      await dropSliderAt(tester, sliderNamed('Change Height'), 0.5);
      expect(find.text('500'), findsOneWidget);
      expect(tester.getSize(find.byType(FluentGaugeChart)).height, 500);
      // A gauge is a half disc, so a taller box is only worth radius up to the
      // point the width binds — which is exactly what a live height knob has to
      // show and a dead one cannot.
      expect(
        gaugePainter(tester).layout.outerRadius,
        greaterThan(before),
        reason: 'the arc must grow into the height it was given',
      );
    });

    testWidgets('the current-value slider swings the needle', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(gaugePainter(tester).needleRotationDegrees, 90);

      await dropSliderAt(tester, sliderNamed('Change Current Value'), 0);
      expect(find.text('0%'), findsOneWidget);
      expect(
        gaugePainter(tester).needleRotationDegrees,
        0,
        reason: 'the minimum points the needle at the left end of the arc',
      );

      await dropSliderAt(tester, sliderNamed('Change Current Value'), 1);
      // The readout, not the painted `100%`: the value inside the arc is
      // trimmed to what fits the hole, and every glyph of the test font is a
      // square of the font size, so four characters do not fit here and would
      // not be the demo's fault.
      expect(find.text('100'), findsOneWidget);
      expect(gaugePainter(tester).needleRotationDegrees, 180);

      await dropSliderAt(tester, sliderNamed('Change Current Value'), 0.5);
      expect(gaugePainter(tester).needleRotationDegrees, 90);
    });

    testWidgets('the hide-min-max checkbox drops both limit labels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(gaugePainter(tester).minLabel, '0');
      expect(gaugePainter(tester).maxLabel, '100');

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        gaugePainter(tester).minLabel,
        isNull,
        reason: 'hideMinMax has to reach the painter, not just the checkbox',
      );
      expect(gaugePainter(tester).maxLabel, isNull);

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(gaugePainter(tester).minLabel, '0');
      expect(gaugePainter(tester).maxLabel, '100');
    });

    testWidgets('the rounded-corners switch reshapes the arc ends', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Rect> square = arcBounds(tester);

      await tapAndSettle(tester, find.text('Rounded Corners OFF'));
      expect(find.text('Rounded Corners ON'), findsOneWidget);
      // A corner radius trims the sharp ends off every band, so the bounding
      // box of each one closes in. Comparing the paths is the only way to see
      // it: the label flipping proves the switch moved, not the arc.
      expect(
        arcBounds(tester),
        isNot(square),
        reason: 'roundCorners must change the arc geometry, not just the label',
      );

      await tapAndSettle(tester, find.text('Rounded Corners ON'));
      expect(arcBounds(tester), square);
    });

    testWidgets('legendMultiSelect keeps a second band lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Widened first: all three legend rows have to be on screen before two of
      // them can be selected.
      await dropSliderAt(tester, sliderNamed('Change Width'), 1);

      await mouseClick(tester, find.text('Low Risk'));
      expect(gaugePainter(tester).opacities, <double>[1, 0.1, 0.1]);
      await mouseClick(tester, find.text('Medium Risk'));
      expect(
        gaugePainter(tester).opacities,
        <double>[0.1, 1, 0.1],
        reason: 'single select keeps only the last legend pressed',
      );

      await tapAndSettle(tester, find.text('legendMultiSelect OFF'));
      expect(find.text('legendMultiSelect ON'), findsOneWidget);
      await tapAndSettle(tester, find.text('Low Risk'));
      expect(
        gaugePainter(tester).opacities,
        <double>[1, 1, 0.1],
        reason: 'multi select must let the second press join the first',
      );
    });

    testWidgets('the gradient switch relabels itself and leaves fills flat', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Color> flat = gaugePainter(tester).colours;

      await mouseClick(tester, find.text('Disable Gradient'));
      expect(find.text('Enable Gradient'), findsOneWidget);
      // `enableGradient` has no counterpart on FluentGaugeChart and the section
      // says so: the switch keeps upstream's control set and drives nothing but
      // its own label. Pinned rather than skipped, so the day the port grows a
      // gradient this test is the one that notices.
      expect(gaugePainter(tester).colours, flat);

      await mouseClick(tester, find.text('Enable Gradient'));
      expect(find.text('Disable Gradient'), findsOneWidget);
    });

    testWidgets('hovering a band opens the reading for every live band', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      final TestGesture mouse = await hoverAt(
        tester,
        bandPoint(tester, 0),
        what: 'the Low Risk band',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(find.text('Current value is 50/100'), findsOneWidget);
      expect(find.text('0 - 33'), findsOneWidget);

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });
  });

  group('gauge chart single segment', () {
    final DocsSection section = sectionOf(
      'charts-gaugechart--gauge-chart-single-segment',
    );

    testWidgets('the current-value slider moves the split it is measuring', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(segmentSizes(tester), <double>[50, 50]);

      // This section wires the same number to the needle AND to both segment
      // sizes, so the knob has to move the shading as well as the pointer.
      await dropSliderAt(tester, sliderNamed('Change Current Value'), 1);
      expect(segmentSizes(tester), <double>[100, 0]);
      expect(gaugePainter(tester).needleRotationDegrees, 180);

      await dropSliderAt(tester, sliderNamed('Change Current Value'), 0);
      expect(segmentSizes(tester), <double>[0, 100]);
      expect(gaugePainter(tester).needleRotationDegrees, 0);
    });

    testWidgets('the rounded-corners switch reshapes the arc ends', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Rect> square = arcBounds(tester);

      await mouseClick(tester, find.text('Rounded Corners OFF'));
      expect(find.text('Rounded Corners ON'), findsOneWidget);
      expect(arcBounds(tester), isNot(square));

      await mouseClick(tester, find.text('Rounded Corners ON'));
      expect(arcBounds(tester), square);
    });

    testWidgets('the gradient switch relabels itself and leaves fills flat', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Color> flat = gaugePainter(tester).colours;

      // The second copy of the inert control the Basic section carries: it is
      // pinned here too so that a port which grows a gradient has to update
      // both sections rather than half of them.
      await mouseClick(tester, find.text('Disable Gradient'));
      expect(find.text('Enable Gradient'), findsOneWidget);
      expect(gaugePainter(tester).colours, flat);

      await mouseClick(tester, find.text('Enable Gradient'));
      expect(find.text('Disable Gradient'), findsOneWidget);
    });

    testWidgets('the size sliders resize the gauge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentGaugeChart)),
        const Size(252, 173),
      );

      await dropSliderAt(tester, sliderNamed('Change Width'), 1);
      await dropSliderAt(tester, sliderNamed('Change Height'), 0.4);
      // Read back rather than assumed: the rail is inset by the thumb, so a
      // fraction of its box is not a fraction of its range anywhere but the
      // middle and the two ends. What matters is that the box is the slider's
      // number, whatever that number turned out to be.
      final Size asked = Size(
        tester.widget<FluentSlider>(sliderNamed('Change Width')).value,
        tester.widget<FluentSlider>(sliderNamed('Change Height')).value,
      );
      expect(asked.width, 1000);
      expect(asked.height, isNot(173));
      expect(tester.getSize(find.byType(FluentGaugeChart)), asked);
      expect(
        gaugePainter(tester).layout.size,
        asked,
        reason: 'the gauge must solve its geometry on the new box',
      );
    });
  });

  group('gauge chart responsive', () {
    final DocsSection section = sectionOf(
      'charts-gaugechart--gauge-chart-responsive',
    );

    testWidgets('the gauge fills the width it is handed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(gaugePainter(tester).layout.size.width, 1600);
      // 75 of 0..100 over a half turn.
      expect(gaugePainter(tester).needleRotationDegrees, 135);
      expect(find.text('75%'), findsOneWidget);

      await pumpSection(tester, section, size: const Size(600, 1400));
      expect(
        gaugePainter(tester).layout.size.width,
        600,
        reason: 'no width prop means the plot is whatever box it is given',
      );
      expect(gaugePainter(tester).needleRotationDegrees, 135);
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

/// The one gauge painter in the tree.
FluentGaugeChartPainter gaugePainter(WidgetTester tester) =>
    paintersOf<FluentGaugeChartPainter>(tester).first;

/// Every band's bounding box, in band order.
List<Rect> arcBounds(WidgetTester tester) => gaugePainter(
  tester,
).arcs.map((FluentGaugeArc arc) => arc.path.getBounds()).toList();

/// Every resolved band's size, in sweep order from the minimum.
List<double> segmentSizes(WidgetTester tester) => gaugePainter(
  tester,
).layout.segments.map((FluentGaugeSegment segment) => segment.size).toList();

/// The slider whose accessible name is [label].
///
/// The three sliders on each of these sections are identical boxes in a `Wrap`,
/// so an index would silently test the wrong one the day a control is inserted
/// above it. The names are the demo's own `semanticLabel`s.
Finder sliderNamed(String label) => find.ancestor(
  of: find.bySemanticsLabel(label),
  matching: find.byType(FluentSlider),
);

/// A screen point inside band [index] of the gauge.
///
/// The bands are painted; the boxes over them are their bounding rects, and the
/// three bands of this gauge only overlap at their corners, so the centre of a
/// band's own bounds is inside that band and nothing else.
Offset bandPoint(WidgetTester tester, int index) {
  final FluentGaugeChartPainter painter = gaugePainter(tester);
  final FluentGaugeArc arc = painter.arcs.firstWhere(
    (FluentGaugeArc arc) => arc.segmentIndex == index,
  );
  return tester.getTopLeft(plotOf<FluentGaugeChartPainter>()) +
      painter.layout.origin +
      arc.path.getBounds().center;
}
