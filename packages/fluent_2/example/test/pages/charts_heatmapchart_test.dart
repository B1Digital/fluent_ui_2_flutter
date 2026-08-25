import 'dart:async';

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// HeatMapChart's page carries two demos, each with the same pair of size
/// sliders and an interactive legend strip.
///
/// Nothing a heat map draws is a widget: the cells, their numbers and both sets
/// of axis labels are all one `CustomPaint`. So the assertions below read the
/// delegate's resolved cells and the axis specs off the painter — the same
/// objects the canvas and the hit test are driven from.
void main() {
  const String page = 'charts-heatmapchart';

  group('heat map chart basic', () {
    final DocsSection section = sectionOf(
      'charts-heatmapchart--heat-map-chart-basic',
    );

    testWidgets('the grid is five rows by seven columns', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The demo declares eight dates but never plots the eighth, and a heat
      // map's axes come from the data rather than from the author's list — so
      // the grid is 5x7. Twenty-eight of those bands are the authored points
      // and the other seven are the transparent misses the data set fills in;
      // a delegate that dropped the misses would leave holes in the grid a
      // user could not tab through.
      expect(_cells(tester), hasLength(35));
      expect(
        _cells(
          tester,
        ).where((FluentHeatMapCellGeometry c) => !c.cell.isPlaceholder),
        hasLength(28),
      );
    });

    testWidgets('laying the cells out prints nothing to the console', (
      WidgetTester tester,
    ) async {
      final List<String> printed = <String>[];
      await runZoned(
        () async => pumpSection(tester, section),
        zoneSpecification: ZoneSpecification(
          print: (Zone _, ZoneDelegate _, Zone _, String line) =>
              printed.add(line),
        ),
      );

      // `FluentHeatMapChartDelegate.cellsFor` carries a leftover debug probe
      // that prints the two scale ranges once per cell, on every layout pass.
      // It is behind an `assert`, so a release build is clean and no pixel
      // moves — but every debug run of an app with a heat map on screen floods
      // the console, which is where a real exception would otherwise be seen.
      expect(
        printed,
        isEmpty,
        // Only the first line is quoted: mounting this demo emits one per cell
        // per layout pass, and printing all of them would bury the failure the
        // way the probe itself buries a real one.
        reason:
            'a chart must not print while it lays itself out; got '
            '${printed.length} lines, the first being "${printed.firstOrNull}"',
      );
    });

    testWidgets('the y formatter names the states rather than the keys', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The data is keyed p1..p5 and only `yAxisStringFormatter` turns those
      // into place names, so a formatter that never reached the axis would
      // label the rows p1..p5 instead.
      expect(cartesianPainter(tester).yAxisPrimary.tickLabels.toSet(), <String>{
        'Ohio',
        'Alaska',
        'Texas',
        'DC',
        'NYC',
      });
    });

    testWidgets('the width slider widens every cell', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        tester.getSize(find.byType(FluentHeatMapChart)),
        const Size(450, 350),
      );

      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(tester.getSize(find.byType(FluentHeatMapChart)).width, 1000);
      final double wide = _cells(tester).first.rect.width;

      // The chart's own reflow floors the plot at its minimum width, so the
      // narrow end is not 200 pixels of plot — but it is still narrower than
      // the wide end, and the cells have to follow it.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 0);
      expect(tester.getSize(find.byType(FluentHeatMapChart)).width, 200);
      final double narrow = _cells(tester).first.rect.width;
      expect(narrow, lessThan(wide));

      // Round trip through the end of the rail, the one fraction that names an
      // exact value through the rail's own 8px inset.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_cells(tester).first.rect.width, closeTo(wide, 0.01));
    });

    testWidgets('the width slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The demo nests two scrollers around the rail — the story's own and the
      // chart's sideways one — and either would claim a mouse press that
      // travels a pixel. `tester.tap` never enters that arena.
      await mouseClick(tester, find.byType(FluentSlider).first);
      expect(
        tester.getSize(find.byType(FluentHeatMapChart)).width,
        isNot(450),
        reason: 'a mouse press on the rail must move the width',
      );
    });

    testWidgets('the height slider heightens every cell', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double short = _cells(tester).first.rect.height;

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(find.byType(FluentHeatMapChart)).height, 1000);
      expect(_cells(tester).first.rect.height, greaterThan(short));

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 0);
      expect(tester.getSize(find.byType(FluentHeatMapChart)).height, 200);
      expect(_cells(tester).first.rect.height, lessThan(short));
    });

    testWidgets('selecting a legend dims every other legend', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_litLegends(tester), hasLength(5));

      // Which row is on screen depends on how many the strip could fit, so the
      // row's own item is the honest way to name the legend under test.
      final Finder rows = find.byType(FluentChartLegendRow);
      final String title = tester
          .widget<FluentChartLegendRow>(rows.first)
          .item
          .title;

      await tapAndSettle(tester, rows.first, what: 'the $title legend');
      expect(tester.widget<FluentChartLegendRow>(rows.first).selected, isTrue);
      expect(_litLegends(tester), <String>{title});
      // The miss rects carry no fill opacity at all, so a selection must leave
      // them exactly where they were.
      expect(
        _cells(tester)
            .where((FluentHeatMapCellGeometry c) => c.cell.isPlaceholder)
            .every((FluentHeatMapCellGeometry c) => c.opacity == 1),
        isTrue,
      );

      // The single-mode legend toggles, so the same click clears it again.
      await tapAndSettle(tester, rows.first, what: 'the $title legend');
      expect(tester.widget<FluentChartLegendRow>(rows.first).selected, isFalse);
      expect(_litLegends(tester), hasLength(5));
    });

    testWidgets('hovering a cell opens the popover with its own story', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Widened first: at the default width the plot reflows past its box and
      // the right-hand columns sit outside the scroller, where nothing
      // hit-tests.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);

      final FluentHeatMapCellGeometry cell = _cells(
        tester,
      ).firstWhere((FluentHeatMapCellGeometry c) => !c.cell.isPlaceholder);
      final TestGesture mouse = await hoverAt(
        tester,
        tester.getTopLeft(_plot()) + cell.rect.center,
        what: 'a heat map cell',
      );

      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(
        find.text(cell.cell.descriptionMessage!),
        findsOneWidget,
        reason: 'the popover body is the cell\'s own description',
      );

      await mouseAway(tester, mouse);
      expect(find.byType(FluentChartPopover), findsNothing);
    });
  });

  group('heat map chart custom accessibility', () {
    final DocsSection section = sectionOf(
      'charts-heatmapchart--heat-map-chart-custom-accessibility',
    );

    testWidgets('the x formatter prefixes every year', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Widened so `hideTickOverlap` keeps every column label: flutter_test
      // measures with a face whose every glyph is a square of the font size,
      // roughly twice Selawik's advance, so the 450-wide default drops labels a
      // browser keeps.
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);

      expect(cartesianPainter(tester).xAxis.tickLabels.toSet(), <String>{
        'FY 1980',
        'FY 1990',
        'FY 2000',
        'FY 2010',
        'FY 2020',
      });
      expect(cartesianPainter(tester).yAxisPrimary.tickLabels.toSet(), <String>{
        'CHN',
        'IND',
        'USA',
        'IDN',
        'PAK',
      });
    });

    testWidgets('every populated cell carries its SI-formatted count', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Five countries by five decades, all populated: the demo's filter drops
      // the seed column, not any cell.
      expect(_cells(tester), hasLength(25));
      expect(
        _cells(
          tester,
        ).every((FluentHeatMapCellGeometry c) => !c.cell.isPlaceholder),
        isTrue,
      );
      expect(
        _cells(tester).map((FluentHeatMapCellGeometry c) => c.cell.rectText),
        contains('1.4B'),
      );
    });

    testWidgets('the size sliders drive this demo too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Size cell = _cells(tester).first.rect.size;

      await mouseClick(tester, find.byType(FluentSlider).first);
      await dropSliderAt(tester, find.byType(FluentSlider).first, 1);
      expect(_cells(tester).first.rect.width, greaterThan(cell.width));

      await dropSliderAt(tester, find.byType(FluentSlider).at(1), 1);
      expect(tester.getSize(find.byType(FluentHeatMapChart)).height, 1000);
      expect(_cells(tester).first.rect.height, greaterThan(cell.height));
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

/// The chart's plot, which is the space the painter's coordinates are local to.
Finder _plot() => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
);

/// Every cell the delegate resolved against the live band scales.
List<FluentHeatMapCellGeometry> _cells(WidgetTester tester) {
  final FluentCartesianChartPainter painter = cartesianPainter(tester);
  return (painter.delegate as FluentHeatMapChartDelegate).cellsFor(
    cartesianContext(painter),
  );
}

/// The legends whose cells are still painted at full strength.
Set<String> _litLegends(WidgetTester tester) => <String>{
  for (final FluentHeatMapCellGeometry cell in _cells(tester))
    if (!cell.cell.isPlaceholder && cell.opacity == 1) cell.cell.legend,
};
