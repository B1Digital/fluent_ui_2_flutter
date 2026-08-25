import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// PolarChart's page is one section with two size sliders over a two-series
/// radar. Everything else it can be asked to do it does through the chart
/// itself: a legend row that dims the other series, a marker that opens a
/// popover under the pointer, and a roving arrow-key traversal that opens the
/// same popover without one.
///
/// The chart paints its grid, its series and its ticks into three
/// [CustomPaint]s and exposes its solved geometry through
/// [FluentPolarChartState.layout], which is where the marker positions these
/// tests aim at come from.
void main() {
  const String page = 'charts-polarchart';
  final DocsSection section = sectionOf('charts-polarchart--polar-chart-basic');

  group('polar chart basic', () {
    testWidgets('the width slider resizes the plot under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(tester.getSize(plot).width, 600);
      expect(layoutOf(tester).centre.dx, 300);

      // A real mouse press at the far end of the rail: `mouseClickAt` travels
      // two pixels between press and release — the drag slop a scroll view can
      // steal a slider press inside — and the rail clamps past its end, so the
      // travel cannot overshoot the maximum.
      final Rect rail = tester.getRect(sliderNamed('Change Width'));
      await mouseClickAt(
        tester,
        Offset(rail.right - 0.5, rail.center.dy),
        what: 'the width slider',
      );
      expect(find.text('1000'), findsOneWidget);
      expect(tester.getSize(plot).width, 1000);
      expect(
        layoutOf(tester).centre.dx,
        500,
        reason: 'the plot re-centres on the new width, so the geometry moved',
      );

      // The slider runs to zero and the demo floors the chart at 40 rather than
      // handing the box under the legend strip a negative size — so zero is a
      // supported state and not a crash.
      await dropSliderAt(tester, sliderNamed('Change Width'), 0);
      expect(find.text('0'), findsOneWidget);
      expect(tester.getSize(plot).width, 40);
      expect(layoutOf(tester).centre.dx, 20);
    });

    testWidgets('the height slider resizes the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double before = tester.getSize(plot).height;

      await dropSliderAt(tester, sliderNamed('Change Height'), 1);
      expect(find.text('1000'), findsOneWidget);
      expect(
        tester.getSize(plot).height,
        greaterThan(before),
        reason: 'the legend strip is taken off the height, not off the slider',
      );
      // The radar is inscribed in the shorter side, so a taller box only counts
      // while the height is the binding dimension — which it is here.
      expect(layoutOf(tester).centre.dy, greaterThan(before / 2));

      // Zero floors the chart at 40, and the legend strip's 32 comes off that
      // before the plot is sized — which is the whole reason the demo carries a
      // floor at all, and is the arithmetic a regression here would break.
      await dropSliderAt(tester, sliderNamed('Change Height'), 0);
      expect(tester.getSize(plot).height, 8);
    });

    testWidgets('a legend row dims the series it did not select', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(activeLegends(tester), isEmpty);

      await mouseClick(tester, find.text('Mike'));
      expect(
        activeLegends(tester),
        <String>{'Mike'},
        reason: 'the painter dims every series outside the active set',
      );

      await mouseClick(tester, find.text('Mike'));
      expect(
        activeLegends(tester),
        isEmpty,
        reason: 'pressing the selected legend again clears the selection',
      );
    });

    testWidgets('hovering a legend row highlights without selecting it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Hover-highlight and selection reach the painter through the same set,
      // and only the pointer leaving tells them apart: a selection would
      // survive it.
      final TestGesture mouse = await mouseHover(tester, find.text('Lily'));
      expect(activeLegends(tester), <String>{'Lily'});
      await mouseAway(tester, mouse);
      expect(activeLegends(tester), isEmpty);
    });

    testWidgets('the arrow keys walk the markers and open each popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // A canvas has nothing focusable of its own, so the press on the plot is
      // what hands the roving group its focus.
      await tapAndSettle(
        tester,
        find.byType(FluentPolarChart),
        what: 'the plot',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(stateOf(tester).activePointId, '0-1');
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(find.text('Chinese'), findsOneWidget);
      expect(find.text('98'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(stateOf(tester).activePointId, '0-2');
      expect(find.text('English'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(stateOf(tester).activePointId, '0-1');
    });

    testWidgets('hovering a marker opens its popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentPolarMarker marker = layoutOf(tester).markers.first;
      expect(marker.legend, 'Mike');

      final TestGesture mouse = await hoverAt(
        tester,
        markerPoint(tester, marker),
        what: "Mike's Math marker",
      );
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'the pointer is inside the marker the chart drew',
      );
      expect(find.text('Math'), findsWidgets);
      expect(find.text('120'), findsOneWidget);

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
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

/// The chart's state, which publishes the solved layout for exactly this.
FluentPolarChartState stateOf(WidgetTester tester) =>
    tester.state<FluentPolarChartState>(find.byType(FluentPolarChart));

/// The geometry the chart last painted.
FluentPolarLayout layoutOf(WidgetTester tester) => stateOf(tester).layout;

/// The grid layer, whose box is the plot and whose top-left is the origin every
/// marker position is measured from.
Finder get plot => plotOf<FluentPolarGridPainter>();

/// The legends currently driving the series painter's dimming.
Set<String> activeLegends(WidgetTester tester) =>
    paintersOf<FluentPolarSeriesPainter>(tester).first.activeLegends;

/// The slider whose accessible name is [label].
Finder sliderNamed(String label) => find.ancestor(
  of: find.bySemanticsLabel(label),
  matching: find.byType(FluentSlider),
);

/// The screen point [marker] was drawn at.
///
/// Markers are two-pixel dots on a canvas with no widget of their own, so the
/// layout's own centre-relative position is the only description of where one
/// is — and putting the pointer anywhere else would test nothing.
Offset markerPoint(WidgetTester tester, FluentPolarMarker marker) =>
    tester.getTopLeft(plot) + layoutOf(tester).centre + marker.position;
