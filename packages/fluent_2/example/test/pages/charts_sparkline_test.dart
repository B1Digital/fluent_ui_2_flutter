import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Sparkline's page carries no knobs at all: both sections are prop-driven, so
/// what has to be proved is that each prop reached the plot and that the page's
/// own "Don't enable a hover state" rule holds under a real pointer.
void main() {
  const String page = 'charts-sparkline';

  group('sparkline basic', () {
    final DocsSection section = sectionOf('charts-sparkline--sparkline-basic');

    testWidgets('every sparkline in the prose and the table paints', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Two inline in the sentence plus one per table row. A sparkline whose
      // series failed the min-render gate collapses to a SizedBox.shrink and
      // would go missing here rather than merely look wrong.
      expect(find.byType(FluentSparkline), findsNWidgets(10));
      expect(sparklinePlots(tester), findsNWidgets(10));
    });

    testWidgets('showLegend alone decides whether the value text appears', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Rows 3, 4 and 5 pass showLegend: false, and only their legends carry
      // these two strings. A sparkline that painted its legend regardless would
      // put them on screen.
      expect(
        find.text('464.64'),
        findsNothing,
        reason: 'row 4 asked for no legend, so its 464.64 must not render',
      );
      expect(
        find.text('46.49'),
        findsNothing,
        reason: 'row 5 asked for no legend, so its 46.49 must not render',
      );
      // sl1 inline, row 1 and row 2 all show the same legend string.
      expect(find.text('19.64'), findsNWidgets(3));
      expect(find.text('541.44'), findsOneWidget);
    });

    testWidgets('the default plot is 80x20 and spans its own width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder plot = sparklinePlots(tester).first;
      expect(tester.getSize(plot), const Size(80, 20));

      // The x scale's range is the widget's width, so the first and last vertex
      // must sit on the two edges. A layout that kept a stale scale — the
      // upstream useEffect([]) defect the port deliberately does not
      // reproduce — would place them anywhere but there.
      final List<Offset> vertices = sparklineVertices(tester, plot);
      expect(vertices.first.dx, 0);
      expect(vertices.last.dx, closeTo(80, 0.01));
    });

    testWidgets('a real pointer resting on a sparkline changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder plot = sparklinePlots(tester).first;
      final String before = textSnapshot(tester);
      final FluentSparklinePainter painter = sparklinePainter(tester, plot);

      // The page's Don'ts are explicit: "Don't enable a hover state". A
      // sparkline that grew a popover, a marker or a value swap under the
      // cursor would break the one rule this component is specified by.
      await hoverOver(tester, plot);
      expect(textSnapshot(tester), before);
      expect(sparklinePlots(tester), findsNWidgets(10));
      expect(sparklinePainter(tester, plot).colour, painter.colour);
    });
  });

  group('sparkline dimensions', () {
    final DocsSection section = sectionOf(
      'charts-sparkline--sparkline-dimensions',
    );

    testWidgets('each row renders at the size its label claims', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder plots = sparklinePlots(tester);
      expect(plots, findsNWidgets(4));

      // The rows are declared Default, width, height, both, and the whole
      // section exists to show those four sizes apart. A width or height prop
      // that never reached the CustomPaint would collapse them onto one size.
      expect(tester.getSize(plots.at(0)), const Size(80, 20));
      expect(tester.getSize(plots.at(1)), const Size(150, 20));
      expect(tester.getSize(plots.at(2)), const Size(80, 40));
      expect(tester.getSize(plots.at(3)), const Size(200, 60));
    });

    testWidgets('a wider plot stretches the geometry, not just the box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder plots = sparklinePlots(tester);
      final List<Offset> normal = sparklineVertices(tester, plots.at(0));
      final List<Offset> wide = sparklineVertices(tester, plots.at(1));
      final List<Offset> tall = sparklineVertices(tester, plots.at(2));

      expect(wide.length, normal.length);
      expect(wide.last.dx, closeTo(150, 0.01));
      // Same data, taller box: the y range grows, so the extremes separate
      // further. A box that resized without re-scaling would leave these equal.
      final double normalSpan = _span(normal.map((Offset o) => o.dy));
      expect(_span(tall.map((Offset o) => o.dy)), greaterThan(normalSpan));
    });

    testWidgets('the legend sits beside every plot at its own height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // All four rows pass showLegend: true with the same legend string.
      expect(find.text('89.7'), findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        final Rect plot = tester.getRect(sparklinePlots(tester).at(i));
        final Rect label = tester.getRect(find.text('89.7').at(i));
        expect(
          label.left,
          greaterThanOrEqualTo(plot.right),
          reason:
              'row $i drew its value text over the plot rather than after '
              'it',
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

/// Every sparkline plot in the tree.
///
/// Not `find.byType(CustomPaint)`: a Fluent subtree is full of them — focus
/// rings, legend swatches — and only the ones carrying a
/// [FluentSparklinePainter] are the chart itself.
Finder sparklinePlots(WidgetTester tester) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is CustomPaint && widget.painter is FluentSparklinePainter,
);

/// The painter behind [plot].
FluentSparklinePainter sparklinePainter(WidgetTester tester, Finder plot) =>
    tester.widget<CustomPaint>(plot).painter! as FluentSparklinePainter;

/// The resolved vertex table behind [plot].
///
/// The line and area are paths, which cannot be read back; the vertices are the
/// same numbers before they were turned into one, so they are the only way to
/// assert a sparkline scaled to the size it was given.
List<Offset> sparklineVertices(WidgetTester tester, Finder plot) =>
    sparklinePainter(tester, plot).layout.vertices;

double _span(Iterable<double> values) =>
    values.reduce((double a, double b) => a > b ? a : b) -
    values.reduce((double a, double b) => a < b ? a : b);
