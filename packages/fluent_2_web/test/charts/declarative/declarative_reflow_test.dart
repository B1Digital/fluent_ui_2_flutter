// The claim spec §5.1 rests on, checked independently of the grid test that
// landed with it.
//
// `FluentResponsiveChartHost` was deleted on the argument that Flutter's
// constraint pass already is upstream's measure-and-inject cycle
// (`ResponsiveContainer.tsx:23-61`, `:79-91`). That argument holds only if a
// narrower box re-lays-out the PAINTED chart, not merely the widget wrapping
// it — the deleted host's own defect was a wrapper whose measurements went
// nowhere, and a box that shrinks around a chart drawn at a fixed size looks
// identical from the outside.
//
// `declarative_chart_test.dart`'s reflow test measures cell boxes and the
// column boundary of a two-cell grid. This file measures the single-plot case
// and the geometry inside it: `FluentCartesianLayout.plotRect`, the rectangle
// every mark is placed in, and then the bar itself, located by hit-testing
// because a hit region IS the painted bar rect — `vertical_bar_chart.dart:1137`
// passes `bar.rect` straight through.
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_painter.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/declarative_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// The two-bin histogram the route tests use, so this file exercises the
  /// declarative path end to end rather than a hand-built chart: two five-wide
  /// bins over [0, 10) with the half-open callouts of
  /// `PlotlySchemaAdapter.ts:1882`. The figure declares no width or height, so
  /// nothing but the enclosing box can decide the geometry.
  const figure = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'type': 'histogram',
        'x': <Object?>[0, 1, 2, 5, 6, 7, 8, 9],
        'y': <Object?>[10, 10, 10, 2, 2, 2, 2, 2],
        'xbins': <String, Object?>{'start': 0, 'end': 10, 'size': 5},
      },
    ],
  };

  /// Mounts the figure in a [width]-wide box, from a clean tree.
  ///
  /// The empty pump first is load-bearing. Re-pumping the same widget keeps the
  /// chart's `State`, and a popover opened by an earlier tap survives into the
  /// next one — which reads as a hit at every position after the first real
  /// one, and turns the scan below into a solid block of false positives.
  Future<void> pumpAt(WidgetTester tester, double width) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Align(
          // Top-left rather than centred, so an offset below is the chart's own
          // offset plus a known origin instead of a re-centred one.
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            // 400 clears one 350-tall cell (`kPlotlyDefaultCellHeight`); the
            // height is held fixed because only the width claim is under test.
            height: 400,
            child: const FluentDeclarativeChart(
              chartSchema: FluentPlotlySchema(plotlySchema: figure),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FluentCartesianLayout paintedLayout(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(FluentVerticalBarChart),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentCartesianChartPainter>()
      .single
      .layout;

  /// Where a bar is painted, as a fraction of the plot's width.
  ///
  /// Walks the plot and returns the midpoint of the run of probes that answer
  /// with a popover, remounting between probes so no reading is the previous
  /// one still on screen. Returns null when nothing answers anywhere, which is
  /// the shape a scan must report rather than an arbitrary number.
  Future<double?> barCentreFraction(WidgetTester tester, double width) async {
    final hits = <double>[];
    // 0.01 is finer than the bar this figure paints, so a run holds more than
    // one sample and its midpoint is a position rather than a single probe.
    for (var f = 0.0; f <= 1.0001; f += 0.01) {
      await pumpAt(tester, width);
      final plot = paintedLayout(tester).plotRect;
      await tester.tapAt(
        tester.getTopLeft(find.byType(FluentVerticalBarChart)) +
            // Five pixels above the axis, where every bar of a positive series
            // is present whatever its height.
            Offset(plot.left + plot.width * f, plot.bottom - 5),
      );
      await tester.pumpAndSettle();
      if (find.byType(FluentChartPopover).evaluate().isNotEmpty) {
        hits.add(f);
      }
    }
    if (hits.isEmpty) {
      return null;
    }
    return (hits.first + hits.last) / 2;
  }

  // 700 and 350 are this file's own two widths, the second exactly half the
  // first, so the delta below is a subtraction rather than a tuned number.
  const wide = 700.0;
  const narrow = 350.0;

  testWidgets('halving the box moves the painted plot rect, not just the box', (
    tester,
  ) async {
    await pumpAt(tester, wide);
    final widePlot = paintedLayout(tester).plotRect;
    await pumpAt(tester, narrow);
    final narrowPlot = paintedLayout(tester).plotRect;

    expect(
      widePlot.width - narrowPlot.width,
      wide - narrow,
      reason:
          'the whole of the lost width must come out of the plot rectangle. '
          'The axis margins are text-driven and the labels did not change, so '
          'any other split means the chart is sized by something other than '
          'the constraints it is given — which is the one thing upstream '
          "needed ResponsiveContainer's ResizeObserver for, and the reason "
          'spec §5.1 deletes the port of it instead of wiring it.',
    );
    expect(
      narrowPlot.right,
      lessThan(widePlot.right),
      reason:
          'and the right edge moves with it. A plot rectangle that keeps its '
          'right edge while reporting a smaller width is a chart drawn at the '
          'old size and clipped, which paints the far bin outside the box.',
    );
  });

  testWidgets(
    'the bar is re-placed proportionally, so it lands on different pixels',
    (tester) async {
      final wideFraction = await barCentreFraction(tester, wide);
      await pumpAt(tester, wide);
      final widePlot = paintedLayout(tester).plotRect;

      final narrowFraction = await barCentreFraction(tester, narrow);
      await pumpAt(tester, narrow);
      final narrowPlot = paintedLayout(tester).plotRect;

      expect(
        <double?>[wideFraction, narrowFraction],
        everyElement(isNotNull),
        reason:
            'a count guard: the scan must have found a painted bar at both '
            'widths before anything is read off where it was. A null here '
            'means the figure rendered no reachable mark, and the assertions '
            'below would be comparing nothing with nothing.',
      );
      expect(
        narrowFraction,
        closeTo(wideFraction!, 0.01),
        reason:
            'the mark sits at the same fraction of the plot at both widths, '
            'which is what re-laying-out means; 0.01 is the scan step, so this '
            'is the tightest claim the measurement supports. A chart drawn at '
            'a fixed pixel size lands at a LARGER fraction of a smaller box '
            'and a smaller fraction of a larger one.',
      );
      expect(
        narrowPlot.left + narrowPlot.width * narrowFraction!,
        lessThan(widePlot.left + widePlot.width * wideFraction),
        reason:
            'and the same fraction of a narrower plot is a different pixel, so '
            'the bar really moved rather than merely being describable '
            'proportionally. Nothing in the figure changed between the two '
            'passes — it declares no width at all — so only the constraint can '
            'have re-placed it, which is what spec §5.1 substitutes for '
            "upstream's ResizeObserver.",
      );
    },
  );
}
