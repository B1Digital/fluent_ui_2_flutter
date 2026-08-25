import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// GanttChart's page carries two demos, both knob-driven: two size sliders and
/// two paint switches on Basic, plus a legend-selection switch on Grouped.
///
/// Every bar the chart draws goes onto one `CustomPaint`, so none of these
/// knobs move a widget. The assertions therefore read the delegate hanging off
/// the painter — the object the canvas was actually driven from — rather than
/// the switch's own `checked`, which would pass on a chart that ignored it.
void main() {
  const String page = 'charts-ganttchart';

  group('gantt chart basic', () {
    final DocsSection section = sectionOf(
      'charts-ganttchart--gantt-chart-basic',
    );

    testWidgets('the width slider resizes the box and rescales the bars', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGanttChart);
      expect(tester.getSize(chart), const Size(600, 350));

      final double narrow = _bars(tester).first.rect.width;
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);

      // The readout under the rail, the box, and the geometry: a chart that
      // resized its container while keeping a stale x scale would satisfy the
      // first two and fail the third.
      expect(find.text('1000'), findsOneWidget);
      expect(tester.getSize(chart).width, 1000);
      final double wide = _bars(tester).first.rect.width;
      expect(wide, greaterThan(narrow));

      // Round trip. The rail maps a tap through its own 8px inset, so a
      // fraction cannot name 600 exactly; returning to the end that *is* exact
      // and comparing against the first reading there proves the same thing.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 0.4);
      expect(tester.getSize(chart).width, lessThan(1000));
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(tester.getSize(chart).width, 1000);
      expect(_bars(tester).first.rect.width, closeTo(wide, 0.01));
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGanttChart);

      // The demo sits inside the story's vertical scroller, and a scrollable
      // that lists the mouse as a drag device claims a press after one pixel of
      // travel — which is exactly what `mouseClick` moves. A rail that only
      // answers `tester.tap` is unreachable with a real pointer.
      await mouseClick(tester, find.byType(FluentSlider).first);
      expect(
        tester.getSize(chart).width,
        isNot(600),
        reason: 'a mouse press on the rail must move the width',
      );
    });

    testWidgets('the height slider restacks the rows', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGanttChart);
      final double pitch = _rowPitch(tester);

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(find.text('1000'), findsOneWidget);
      expect(tester.getSize(chart).height, 1000);
      // Three rows over a taller plot: the band step grows even though the bar
      // height is capped at 24, so the *gaps* are the thing that must move.
      expect(_rowPitch(tester), greaterThan(pitch));
    });

    testWidgets('the gradient switch gives every bar two stops', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder knob = _switchLabelled('Enable Gradient');

      expect(
        _bars(
          tester,
        ).every((FluentGanttBar bar) => bar.startColour == bar.endColour),
        isTrue,
        reason: 'a flat bar must resolve to one colour',
      );

      await tapAndSettle(tester, knob, what: 'the gradient switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isTrue);
      expect(
        _bars(
          tester,
        ).every((FluentGanttBar bar) => bar.startColour != bar.endColour),
        isTrue,
        reason:
            'every point on this demo carries a gradient, so every bar '
            'must resolve to two different stops',
      );
      // The stops only reach the screen through a shader; a delegate that
      // resolved them and then painted a flat fill would pass the check above.
      expect(_probe(tester).shaders, everyElement(isTrue));

      await tapAndSettle(tester, knob, what: 'the gradient switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isFalse);
      expect(_probe(tester).shaders, everyElement(isFalse));
    });

    testWidgets('the rounded-corners switch rounds what is drawn', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder knob = _switchLabelled('Rounded Corners');

      // roundCorners changes no rect and no colour — it swaps drawRect for
      // drawRRect and nothing else — so the draw calls are the only honest
      // evidence that the knob reached the canvas.
      expect(_probe(tester).radii, everyElement(0.0));

      await tapAndSettle(tester, knob, what: 'the rounded-corners switch');
      expect(_probe(tester).radii, everyElement(greaterThan(0.0)));

      await tapAndSettle(tester, knob, what: 'the rounded-corners switch');
      expect(_probe(tester).radii, everyElement(0.0));
    });

    testWidgets('selecting a legend dims the other legend', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);

      expect(
        _bars(tester).every((FluentGanttBar bar) => bar.opacity == 1),
        isTrue,
        reason: 'nothing is selected, so nothing may be dimmed',
      );

      await tapAndSettle(tester, find.text('Max'), what: 'the Max legend');
      final List<FluentGanttBar> bars = _bars(tester);
      // Max owns Job C, which is the third point; Alex owns the other two.
      expect(bars.singleWhere((FluentGanttBar b) => b.index == 2).opacity, 1);
      expect(
        bars.where((FluentGanttBar b) => b.index != 2),
        everyElement(
          isA<FluentGanttBar>().having(
            (FluentGanttBar b) => b.opacity,
            'opacity',
            lessThan(1),
          ),
        ),
      );

      // Clicking the selected legend again clears it, which is the single-mode
      // toggle.
      await tapAndSettle(tester, find.text('Max'), what: 'the Max legend');
      expect(
        _bars(tester).every((FluentGanttBar bar) => bar.opacity == 1),
        isTrue,
      );
    });

    testWidgets('hovering a bar opens the popover for that span', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentCartesianChartPainter painter = cartesianPainter(tester);
      final FluentGanttBar bar = _bars(tester).first;
      final Offset origin = tester.getTopLeft(_plot(tester));

      final TestGesture mouse = await hoverAt(
        tester,
        origin + bar.rect.center,
        what: 'a Gantt bar',
      );
      expect(
        find.byType(FluentChartPopover),
        findsOneWidget,
        reason: 'a bar is a hit region, so the pointer must raise its popover',
      );
      // The popover's header is the row, not the legend (`GanttChart.tsx:298`).
      final int row = bar.index;
      expect(
        find.text(
          '${(painter.delegate as FluentGanttChartDelegate).points[row].y}',
        ),
        findsWidgets,
      );

      // Leaving the plot closes it again (`CartesianChart.tsx` `onExit`).
      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });
  });

  group('gantt chart grouped', () {
    final DocsSection section = sectionOf(
      'charts-ganttchart--gantt-chart-grouped',
    );

    testWidgets('the multi-select switch decides how many legends stay lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder knob = _switchLabelled('Select Multiple Legends');

      // Single mode: the second pick replaces the first, so only the bars of
      // the newest legend stay at full strength.
      await tapAndSettle(tester, find.text('Complete'), what: 'Complete');
      await tapAndSettle(tester, find.text('Not Started'), what: 'Not Started');
      expect(_litLegends(tester), <String>{'Not Started'});

      await tapAndSettle(tester, find.text('Not Started'), what: 'Not Started');
      await tapAndSettle(tester, knob, what: 'the multi-select switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isTrue);

      // Multiple mode: the same two clicks now leave both lit. A switch that
      // moved its own value without reaching `legendSelectionMode` would leave
      // this identical to the single-mode reading above.
      await tapAndSettle(tester, find.text('Complete'), what: 'Complete');
      await tapAndSettle(tester, find.text('Not Started'), what: 'Not Started');
      expect(_litLegends(tester), <String>{'Complete', 'Not Started'});

      // Round trip: back to single, and the next pick collapses the pair to
      // one. Picking a legend the multi-selection already holds would clear it
      // instead — that is the single-mode toggle, not a failure to switch — so
      // the pick has to be the one legend that is not currently selected.
      await tapAndSettle(tester, knob, what: 'the multi-select switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isFalse);
      await tapAndSettle(tester, find.text('Incomplete'), what: 'Incomplete');
      expect(_litLegends(tester), <String>{'Incomplete'});
    });

    testWidgets('the gradient switch reaches all three legend colours', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        _switchLabelled('Enable Gradient'),
        what: 'the gradient switch',
      );
      // Eight points over three legends, each with its own two-stop pair.
      final Set<(Color, Color)> pairs = _bars(
        tester,
      ).map((FluentGanttBar bar) => (bar.startColour, bar.endColour)).toSet();
      expect(pairs.length, 3);
      expect(pairs.every(((Color, Color) pair) => pair.$1 != pair.$2), isTrue);
    });

    testWidgets('the size sliders drive the grouped chart too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentGanttChart);
      expect(tester.getSize(chart), const Size(600, 350));

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(tester.getSize(chart).width, 1000);
      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(chart).height, 1000);
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

/// The switch whose label reads [label].
Finder _switchLabelled(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FluentSwitch));

/// The chart's plot, which is where the painter's coordinates are local to.
Finder _plot(WidgetTester tester) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
);

/// Every bar the Gantt delegate resolved against the live scales.
///
/// Bars are canvas draws, not widgets, so this is the only description of what
/// a knob did to the chart: their rects carry the x scale, their colours carry
/// the gradient switch and their opacity carries the legend selection.
List<FluentGanttBar> _bars(WidgetTester tester) {
  final FluentCartesianChartPainter painter = cartesianPainter(tester);
  return (painter.delegate as FluentGanttChartDelegate).barsFor(
    cartesianContext(painter),
    painter.layout,
  );
}

/// The vertical distance between the two lowest rows.
///
/// The bar height is clamped at 24, so a taller plot can only show itself in
/// the spacing between rows — comparing bar heights would compare two clamps.
double _rowPitch(WidgetTester tester) {
  final List<double> tops =
      _bars(tester)
          .map((FluentGanttBar bar) => bar.rect.top)
          .toSet()
          .toList(growable: false)
        ..sort();
  return tops[1] - tops[0];
}

/// The legends whose bars are still at full strength.
Set<String> _litLegends(WidgetTester tester) {
  final FluentCartesianChartPainter painter = cartesianPainter(tester);
  final FluentGanttChartDelegate delegate =
      painter.delegate as FluentGanttChartDelegate;
  return <String>{
    for (final FluentGanttBar bar in _bars(tester))
      if (bar.opacity == 1) '${delegate.points[bar.index].legend}',
  };
}

/// Replays the delegate's series paint onto a recording canvas.
_SeriesProbe _probe(WidgetTester tester) {
  final FluentCartesianChartPainter painter = cartesianPainter(tester);
  final _SeriesProbe probe = _SeriesProbe();
  painter.delegate.paintSeries(
    probe,
    cartesianContext(painter),
    painter.layout,
    painter.colors,
  );
  return probe;
}

/// Records the two things a Gantt bar's own paint decides.
///
/// `roundCorners` swaps `drawRect` for `drawRRect` and `enableGradient` swaps a
/// flat colour for a shader; neither changes a rect, a widget or a semantics
/// node, so the draw calls are where those knobs become observable at all.
/// Everything the painter does not call is absorbed by [noSuchMethod].
class _SeriesProbe implements Canvas {
  final List<double> radii = <double>[];
  final List<bool> shaders = <bool>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    radii.add(0);
    shaders.add(paint.shader != null);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    radii.add(rrect.blRadiusX);
    shaders.add(paint.shader != null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
