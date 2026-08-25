import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// ScatterChart's page carries four demos. All four have the two size sliders;
/// Default adds the legend-selection switch and Log Axis adds the two scale
/// radio groups.
///
/// A scatter marker is a circle on a canvas, not a widget, so every assertion
/// below reads the delegate's resolved marks — the same list the painter and
/// the hit test are driven from — rather than the knob's own value.
void main() {
  const String page = 'charts-scatterchart';

  group('scatter chart default', () {
    final DocsSection section = sectionOf(
      'charts-scatterchart--scatter-chart-default',
    );

    testWidgets('the width slider spreads the markers along x', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chart = find.byType(FluentScatterChart);
      expect(tester.getSize(chart), const Size(650, 350));
      expect(_marks(tester), hasLength(11));

      final double narrow = _spread(
        tester,
        (FluentScatterMark m) => m.centre.dx,
      );
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(tester.getSize(chart).width, 1000);
      final double wide = _spread(tester, (FluentScatterMark m) => m.centre.dx);
      expect(
        wide,
        greaterThan(narrow),
        reason: 'a wider box must widen the x range the markers are placed on',
      );

      // Round trip through the other end of the rail, which is the only
      // fraction that names an exact value through the rail's 8px inset.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 0);
      expect(tester.getSize(chart).width, 200);
      expect(
        _spread(tester, (FluentScatterMark m) => m.centre.dx),
        lessThan(narrow),
      );
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(
        _spread(tester, (FluentScatterMark m) => m.centre.dx),
        closeTo(wide, 0.01),
      );
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The whole story sits in a vertical scroller and the chart in a
      // horizontal one; both would swallow a mouse press that the rail is
      // supposed to receive. Synthetic `tap` never sees that arena.
      await mouseClick(tester, find.byType(FluentSlider).first);
      expect(
        tester.getSize(find.byType(FluentScatterChart)).width,
        isNot(650),
        reason: 'a mouse press on the rail must move the width',
      );
    });

    testWidgets('the height slider spreads the markers along y', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double short = _spread(
        tester,
        (FluentScatterMark m) => m.centre.dy,
      );

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(find.byType(FluentScatterChart)).height, 1000);
      expect(
        _spread(tester, (FluentScatterMark m) => m.centre.dy),
        greaterThan(short),
      );
    });

    testWidgets('the multi-select switch decides how many series stay lit', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder knob = _switchLabelled('Select Multiple Legends');
      expect(_litSeries(tester), <int>{0, 1, 2});

      // Single mode: the second pick replaces the first.
      await tapAndSettle(tester, find.text('Phase 1'), what: 'Phase 1');
      expect(_litSeries(tester), <int>{0});
      await tapAndSettle(tester, find.text('Milestone'), what: 'Milestone');
      expect(_litSeries(tester), <int>{2});

      await tapAndSettle(tester, knob, what: 'the multi-select switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isTrue);

      // Multiple mode: the same pair of clicks now leaves both series lit. A
      // switch that moved its own value without reaching `legendSelectionMode`
      // would leave this identical to the single-mode reading above.
      await tapAndSettle(tester, find.text('Phase 1'), what: 'Phase 1');
      expect(_litSeries(tester), <int>{0, 2});

      // Round trip. The pick has to be a legend the pair does not already hold:
      // in single mode a click on a selected legend clears the selection.
      await tapAndSettle(tester, knob, what: 'the multi-select switch');
      expect(tester.widget<FluentSwitch>(knob).checked, isFalse);
      await tapAndSettle(tester, find.text('Phase 2'), what: 'Phase 2');
      expect(_litSeries(tester), <int>{1});
    });

    testWidgets('hovering a legend dims the other two series', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The legend's highlight arrives through `onEnter`, which a synthetic tap
      // never sends: this is only reachable with a real pointer.
      final TestGesture mouse = await mouseHover(tester, find.text('Phase 2'));
      expect(_litSeries(tester), <int>{1});

      await mouseAway(tester, mouse);
      expect(
        _litSeries(tester),
        <int>{0, 1, 2},
        reason: 'leaving the row must restore every series to full strength',
      );
    });

    testWidgets('hovering a marker opens the popover for that point', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Marks are emitted last series first, so this is the lone Milestone
      // point at x 75 — the one value on the demo that no other point shares.
      final FluentScatterMark mark = _marks(tester).first;
      final Offset origin = tester.getTopLeft(_plot());

      final TestGesture mouse = await hoverAt(
        tester,
        origin + mark.centre,
        what: 'a scatter marker',
      );
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FluentChartPopover),
          matching: find.text('75'),
        ),
        findsOneWidget,
        reason: 'the popover header is the hovered point\'s own x value',
      );
      expect(
        _marks(tester).first.isActive,
        isTrue,
        reason:
            'the hovered marker inverts its fill, which is the only visual '
            'response a sized marker has',
      );

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
      expect(_marks(tester).any((FluentScatterMark m) => m.isActive), isFalse);
    });
  });

  group('scatter chart date', () {
    final DocsSection section = sectionOf(
      'charts-scatterchart--scatter-chart-date',
    );

    testWidgets('the date axis ticks and every series plots', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_marks(tester), hasLength(15));

      final FluentCartesianChartPainter painter = cartesianPainter(tester);
      expect(painter.delegate.xAxisType, FluentChartAxisType.date);
      expect(painter.xAxis.tickLabels, isNotEmpty);
      expect(
        painter.xAxis.tickLabels.every((String label) => label.isNotEmpty),
        isTrue,
        reason: 'a date tick with no label is an axis that never formatted',
      );
    });

    testWidgets('the width slider re-solves the date axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double narrow = _spread(
        tester,
        (FluentScatterMark m) => m.centre.dx,
      );

      await mouseClick(tester, find.byType(FluentSlider).first);
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(tester.getSize(find.byType(FluentScatterChart)).width, 1000);
      expect(
        _spread(tester, (FluentScatterMark m) => m.centre.dx),
        greaterThan(narrow),
      );
    });
  });

  group('scatter chart string', () {
    final DocsSection section = sectionOf(
      'charts-scatterchart--scatter-chart-string',
    );

    testWidgets('the five categories become the x band ticks', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        cartesianPainter(tester).delegate.xAxisType,
        FluentChartAxisType.category,
      );
      // Two regions over five categories, and a band axis centres each marker
      // in its own band — so the ten markers stand in five columns, not ten.
      expect(_marks(tester), hasLength(10));
      expect(
        _marks(tester).map((FluentScatterMark m) => m.centre.dx).toSet(),
        hasLength(5),
      );

      // `hideTickOverlap` defaults on, and flutter_test measures with a face
      // whose every glyph is a square of the font size — roughly twice
      // Selawik's advance — so the 650-wide default drops a label a browser
      // keeps. Widening the box is the demo's own remedy for that, and at the
      // rail's far end all five categories must be labelled.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(cartesianPainter(tester).xAxis.tickLabels.toSet(), <String>{
        'Electronics',
        'Furniture',
        'Clothing',
        'Toys',
        'Books',
      });
    });

    testWidgets('the height slider re-solves the band scale', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double short = _spread(
        tester,
        (FluentScatterMark m) => m.centre.dy,
      );

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(find.byType(FluentScatterChart)).height, 1000);
      expect(
        _spread(tester, (FluentScatterMark m) => m.centre.dy),
        greaterThan(short),
      );
    });
  });

  group('scatter chart log axis example', () {
    final DocsSection section = sectionOf(
      'charts-scatterchart--scatter-chart-log-axis-example',
    );

    testWidgets('the x scale radio group re-ticks and re-places the x axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_marks(tester), hasLength(30));

      final List<String> logTicks = cartesianPainter(tester).xAxis.tickLabels;
      final double logX = _marks(tester).first.centre.dx;
      final List<String> yTicks = cartesianPainter(
        tester,
      ).yAxisPrimary.tickLabels;

      // A radio only ever reveals itself under the pointer in a browser, and
      // the group sits inside two nested scrollers; a press that the scroller
      // claims would leave the demo on its old scale.
      await mouseClick(tester, _radio(tester, group: 0, label: 'default'));
      expect(
        cartesianPainter(tester).delegate,
        isA<FluentScatterChartDelegate>().having(
          (FluentScatterChartDelegate d) => d.xScaleType,
          'xScaleType',
          FluentAxisScaleType.auto,
        ),
      );
      expect(
        cartesianPainter(tester).xAxis.tickLabels,
        isNot(logTicks),
        reason: 'a linear x axis cannot tick where a log one did',
      );
      expect(_marks(tester).first.centre.dx, isNot(closeTo(logX, 0.5)));
      expect(
        cartesianPainter(tester).yAxisPrimary.tickLabels,
        yTicks,
        reason: 'the x radio must not touch the y axis',
      );

      // Round trip.
      await mouseClick(tester, _radio(tester, group: 0, label: 'log'));
      expect(cartesianPainter(tester).xAxis.tickLabels, logTicks);
      expect(_marks(tester).first.centre.dx, closeTo(logX, 0.01));
    });

    testWidgets('the y scale radio group re-ticks and re-places the y axis', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<String> logTicks = cartesianPainter(
        tester,
      ).yAxisPrimary.tickLabels;
      final List<String> xTicks = cartesianPainter(tester).xAxis.tickLabels;
      final double logY = _marks(tester).first.centre.dy;

      await tapAndSettle(
        tester,
        _radio(tester, group: 1, label: 'default'),
        what: 'the linear y scale',
      );
      expect(
        cartesianPainter(tester).delegate,
        isA<FluentScatterChartDelegate>().having(
          (FluentScatterChartDelegate d) => d.yScaleType,
          'yScaleType',
          FluentAxisScaleType.auto,
        ),
      );
      expect(cartesianPainter(tester).yAxisPrimary.tickLabels, isNot(logTicks));
      expect(_marks(tester).first.centre.dy, isNot(closeTo(logY, 0.5)));
      expect(
        cartesianPainter(tester).xAxis.tickLabels,
        xTicks,
        reason: 'the y radio must not touch the x axis',
      );

      await tapAndSettle(
        tester,
        _radio(tester, group: 1, label: 'log'),
        what: 'the log y scale',
      );
      expect(cartesianPainter(tester).yAxisPrimary.tickLabels, logTicks);
      expect(_marks(tester).first.centre.dy, closeTo(logY, 0.01));
    });

    testWidgets('the size sliders report their value and resize the plot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('700'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(find.text('1000'), findsOneWidget);
      expect(tester.getSize(find.byType(FluentScatterChart)).width, 1000);

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
      expect(find.text('200'), findsOneWidget);
      expect(tester.getSize(find.byType(FluentScatterChart)).height, 200);
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

/// The radio labelled [label] inside the [group]-th radio group.
///
/// Both groups on the Log Axis demo offer the same two labels, so a bare
/// `find.text('log')` matches the x group and the y group alike.
Finder _radio(
  WidgetTester tester, {
  required int group,
  required String label,
}) => find.descendant(
  of: find.byType(FluentRadioGroup<String>).at(group),
  matching: find.text(label),
);

/// The chart's plot, which is the space the painter's coordinates are local to.
Finder _plot() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
);

/// Every marker the delegate resolved against the live scales.
List<FluentScatterMark> _marks(WidgetTester tester) {
  final FluentCartesianChartPainter painter = cartesianPainter(tester);
  return (painter.delegate as FluentScatterChartDelegate).marksFor(
    cartesianContext(painter),
  );
}

/// The distance between the extreme values of [of] over every marker.
///
/// A resize has to move the *scale*, not just the box: comparing one marker's
/// coordinate would also pass on a plot that merely translated.
double _spread(WidgetTester tester, double Function(FluentScatterMark) of) {
  final List<double> values = _marks(tester).map(of).toList(growable: false)
    ..sort();
  return values.last - values.first;
}

/// The series indices still drawn at full strength.
///
/// The dimmed treatment is a flat 0.1 on `markerOpacity`, so "lit" is an exact
/// 1 rather than "the largest opacity present" — the latter would report every
/// series as lit on a chart that dimmed all of them.
Set<int> _litSeries(WidgetTester tester) => <int>{
  for (final FluentScatterMark mark in _marks(tester))
    if (mark.opacity == 1) mark.seriesIndex,
};
