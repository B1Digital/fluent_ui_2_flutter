import 'package:fluent_2/src/charts/area_chart.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2/src/charts/declarative_chart.dart';
import 'package:fluent_2/src/charts/vertical_bar_chart.dart';
import 'package:fluent_2/src/charts/vertical_stacked_bar_chart.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The widget's own three responsibilities, mounted rather than called:
/// group the traces by axis key, lay the groups out in a grid, dispatch each
/// group to its transformer (`DeclarativeChart.tsx:357-637`).
///
/// Every assertion here runs against a MOUNTED widget, because the defect this
/// wave keeps shipping is a transformer that is green in isolation and reached
/// by nothing. `find.byType(FluentVerticalStackedBarChart)` is only satisfied
/// if `_buildChart` really dispatched.
///
/// There is one captured DeclarativeChart story in Oracle B and it is not any
/// of these figures, so every number below is hand-derived from the upstream
/// file named beside it.
void main() {
  /// 400 is deep enough for one 350-tall cell plus the all-up legend
  /// (`kPlotlyDefaultCellHeight`); a figure that also draws the multi-plot
  /// title needs more, and says so at its call site.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double height = 400,
    double width = 700,
  }) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );

  /// A two-cell figure: one bar trace on `x`, one on `x2`, with the four
  /// domains `getGridProperties` needs to place them
  /// (`PlotlySchemaAdapter.ts:3663-3699`).
  ///
  /// `legendgroup` rather than `name` carries the all-up legend title, because
  /// `PlotlySchemaAdapter.ts:3540` reads that key and `:3550` skips a trace
  /// without one; `name` is what the per-cell legend uses (`:3575`).
  Map<String, Object?> twoAxisFigure({bool showLegend = false}) =>
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'name': 's1',
            'legendgroup': 's1',
            'xaxis': 'x',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
          <String, Object?>{
            'type': 'bar',
            'name': 's2',
            'legendgroup': 's2',
            'xaxis': 'x2',
            'x': <Object?>['b'],
            'y': <Object?>[2],
          },
        ],
        'layout': <String, Object?>{
          if (showLegend) 'showlegend': true,
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 0.45],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0.55, 1],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x2',
          },
        },
      };

  testWidgets('a single-trace bar figure renders one vertical stacked bar '
      'chart', (tester) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'bar',
                'x': <Object?>['a', 'b'],
                'y': <Object?>[1, 2],
              },
            ],
          },
        ),
      ),
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsOneWidget,
      reason:
          'DeclarativeChart.tsx:291-294 routes a plain bar figure to the '
          'VSBC.',
    );
  });

  testWidgets('two x axes produce two cells side by side', (tester) async {
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(plotlySchema: twoAxisFigure()),
      ),
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsNWidgets(2),
      reason: 'DeclarativeChart.tsx:482-497 groups traces by their xaxis key.',
    );
    final first = tester
        .getTopLeft(find.byType(FluentVerticalStackedBarChart).first)
        .dx;
    final second = tester
        .getTopLeft(find.byType(FluentVerticalStackedBarChart).last)
        .dx;
    expect(
      second,
      greaterThan(first),
      reason:
          'DeclarativeChart.tsx:562-569 lays the cells out as grid columns, '
          'so the `x2` cell sits to the right of the `x` cell rather than '
          'stacked on top of it.',
    );
  });

  // This is the test that decided against porting `ResponsiveContainer`'s
  // measure-and-inject cycle (`ResponsiveContainer.tsx:23-61, 79-91`) as a
  // widget. Upstream needs a `ResizeObserver` because a React component cannot
  // read its own box; the injected `width`/`height` then reach the chart, which
  // measures the DOM again anyway (`CartesianChart.tsx:107-128` lists them as
  // effect dependencies and takes its real numbers from
  // `getBoundingClientRect` at `:510-525`). Flutter delivers the box directly,
  // so the whole cycle collapses into the constraints the cell already hands
  // down. What follows is the proof of that claim, at both levels the cycle
  // touched: the grid re-divides and each cell re-lays-out.
  testWidgets('halving the available width reflows the grid and every cell', (
    tester,
  ) async {
    final chart = FluentDeclarativeChart(
      chartSchema: FluentPlotlySchema(plotlySchema: twoAxisFigure()),
    );
    // 700 and 350 are this test's own two viewport widths, chosen so the
    // second is exactly half the first and the expectations below are the
    // halves rather than tuned numbers.
    // Measured from the figure's own left edge, because the enclosing `Center`
    // re-centres a narrower figure and every absolute dx below would otherwise
    // land on the same viewport centre in both passes — which is how the first
    // draft of this assertion passed on a grid that had not re-divided at all.
    double secondColumnStart() =>
        tester.getTopLeft(find.byType(FluentVerticalStackedBarChart).last).dx -
        tester.getTopLeft(find.byType(FluentDeclarativeChart)).dx;

    await pump(tester, chart, width: 700);
    final wideCell = tester
        .getSize(find.byType(FluentVerticalStackedBarChart).first)
        .width;
    final wideSecondColumnStart = secondColumnStart();

    await pump(tester, chart, width: 350);
    final narrowCell = tester
        .getSize(find.byType(FluentVerticalStackedBarChart).first)
        .width;
    final narrowSecondColumnStart = secondColumnStart();

    expect(
      wideCell,
      350,
      reason:
          'the two cells of DeclarativeChart.tsx:562-569 are `repeat(2, 1fr)`, '
          'so a 700-wide figure gives each 350.',
    );
    expect(
      narrowCell,
      175,
      reason:
          'and halving the viewport must halve the cell. A cell that stays at '
          '350 means the chart is sized by something other than the '
          'constraints it is given, which is the only thing upstream needed '
          "ResponsiveContainer's ResizeObserver for.",
    );
    expect(
      <double>[wideSecondColumnStart, narrowSecondColumnStart],
      <double>[350, 175],
      reason:
          'the grid itself re-divides, not only the cells inside it: the `x2` '
          'column boundary moves with the figure. A cell can shrink while the '
          'boundary stays put — that is what a fixed-width column would do — '
          'so this is a separate claim from the two above.',
    );
  });

  testWidgets('the multi-plot title only appears in a multi-plot figure', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'bar',
                'x': <Object?>['a'],
                'y': <Object?>[1],
              },
            ],
            'layout': <String, Object?>{'title': 'my title'},
          },
        ),
      ),
    );
    expect(
      find.text('my title'),
      findsNothing,
      reason: 'DeclarativeChart.tsx:561 gates the title div on isMultiPlot.',
    );
  });

  testWidgets('a multi-plot figure does draw the title above the grid', (
    tester,
  ) async {
    final figure = twoAxisFigure();
    final layout = figure['layout']! as Map<String, Object?>;
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            ...figure,
            'layout': <String, Object?>{...layout, 'title': 'my title'},
          },
        ),
      ),
      // The title and its 8px gap sit above the 350-tall cells, so 400 would
      // overflow the flex.
      height: 500,
    );
    expect(
      find.text('my title'),
      findsOneWidget,
      reason:
          'DeclarativeChart.tsx:561 draws the title exactly when '
          'isMultiPlot is true — the other half of the gate above, without '
          'which the title branch could be dead and both tests still pass.',
    );
  });

  testWidgets('an invalid schema renders the error builder instead of '
      'throwing', (tester) async {
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: const FluentPlotlySchema(
          plotlySchema: <String, Object?>{'data': <Object?>[]},
        ),
        errorBuilder: (context, message) => Text('failed: $message'),
      ),
    );
    expect(
      find.textContaining('failed:'),
      findsOneWidget,
      reason:
          'DeclarativeChart.tsx:364 throws; a Flutter build() must not, so '
          'the port routes the message to errorBuilder.',
    );
  });

  testWidgets('legend selection round-trips through onSchemaChange', (
    tester,
  ) async {
    var lastSelection = const <String>[];
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: twoAxisFigure(showLegend: true),
        ),
        onSchemaChange: (schema) => lastSelection = schema.selectedLegends,
      ),
    );
    // The only legend in the tree is the all-up one at
    // `DeclarativeChart.tsx:634`: every cell chart is transformed with
    // `hideLegend: isMultiPlot || …` (`PlotlySchemaAdapter.ts:3584`), so a
    // multi-plot cell draws none of its own. The count is asserted because it
    // is what makes the tap below unambiguous.
    expect(
      find.byType(FluentChartLegend),
      findsOneWidget,
      reason:
          'the all-up legend at DeclarativeChart.tsx:634 and no cell legend, '
          'because PlotlySchemaAdapter.ts:3584 hides those in a multi-plot '
          'figure.',
    );
    await tester.tap(find.text('S1'));
    await tester.pumpAndSettle();
    expect(
      lastSelection,
      <String>['s1'],
      reason:
          'DeclarativeChart.tsx:396-401 fires onSchemaChange with the new '
          'selection; the legend title is capitalised for display only '
          '(useLegendsStyles.styles.ts:56), so the raw title round-trips.',
    );
  });

  testWidgets('a new schema identity resets the legend selection', (
    tester,
  ) async {
    const first = FluentPlotlySchema(
      plotlySchema: <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'name': 's1',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
        ],
      },
      selectedLegends: <String>['s1'],
    );
    const second = FluentPlotlySchema(
      plotlySchema: <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'name': 's1',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
        ],
      },
    );
    await pump(tester, const FluentDeclarativeChart(chartSchema: first));
    final state = tester.state<State<FluentDeclarativeChart>>(
      find.byType(FluentDeclarativeChart),
    );
    expect(
      (state as dynamic).activeLegends,
      <String>['s1'],
      reason:
          'DeclarativeChart.tsx:391-393 seeds the state from '
          'selectedLegends, so the reset below is a change and not a no-op.',
    );
    await pump(tester, const FluentDeclarativeChart(chartSchema: second));
    expect(
      (state as dynamic).activeLegends,
      isEmpty,
      reason:
          'DeclarativeChart.tsx:403-410 re-reads selectedLegends whenever '
          'chartSchema changes identity, resetting to [] when absent.',
    );
  });

  testWidgets('a figure inside an unbounded scroll view lays out', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: SingleChildScrollView(
          child: FluentDeclarativeChart(
            chartSchema: FluentPlotlySchema(
              plotlySchema: twoAxisFigure(showLegend: true),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      isNull,
      reason:
          'the grid is intrinsically sized — every cell carries its own '
          'height from kPlotlyDefaultCellHeight — so neither the outer column '
          'nor a grid row may demand the unbounded height a scroll view hands '
          'down.',
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsNWidgets(2),
      reason:
          'and the cells are still there, so the assertion above is not '
          'passing on an empty tree.',
    );
  });

  /// A histogram over eight observations, three below 5 and five at or above
  /// it, with `xbins` pinning the edges so the bins do not depend on the
  /// Sturges fallback (`PlotlySchemaAdapter.ts:3413-3441`).
  ///
  /// The `y` column is deliberately not the count: 10 for every observation in
  /// the first bin and 2 for every observation in the second, so `count` (3, 5)
  /// and `sum` (30, 10) disagree in both bins and a `histfunc` that resolved to
  /// the wrong arm could not produce the expected numbers by accident.
  Map<String, Object?> histogramFigure({
    String? histfunc,
    String? histnorm,
    num? layoutHeight,
  }) => <String, Object?>{
    'layout': ?(layoutHeight == null
        ? null
        : <String, Object?>{'height': layoutHeight}),
    'data': <Object?>[
      <String, Object?>{
        'type': 'histogram',
        'x': <Object?>[0, 1, 2, 5, 6, 7, 8, 9],
        'y': <Object?>[10, 10, 10, 2, 2, 2, 2, 2],
        // 0/10/5 are the interval this figure declares, not a tuned
        // constant: two five-wide bins over [0, 10).
        'xbins': <String, Object?>{'start': 0, 'end': 10, 'size': 5},
        'histfunc': ?histfunc,
        'histnorm': ?histnorm,
      },
    ],
  };

  testWidgets('a histogram figure reaches the binning transformer and renders '
      'a vertical bar chart', (tester) async {
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: histogramFigure(layoutHeight: 600),
        ),
      ),
      // Deeper than the 600 the figure declares, so the height assertion
      // below cannot be satisfied by the box simply running out.
      height: 800,
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsNothing,
      reason:
          'PlotlySchemaConverter.ts:517-518 routes a histogram to '
          '`verticalbar`, whose chartMap entry is '
          'transformPlotlyJsonToVBCProps (DeclarativeChart.tsx:303-306) — '
          'never the stacked bar.',
    );
    final chart = tester.widget<FluentVerticalBarChart>(
      find.byType(FluentVerticalBarChart),
    );
    expect(
      chart.data.map((point) => point.y).toList(),
      <double>[3, 5],
      reason:
          'the default histfunc is the COUNT of each bin, not a sum '
          '(PlotlySchemaAdapter.ts:3453-3454): three observations below 5 and '
          'five at or above it. A sum would read 30 and 10.',
    );
    expect(
      chart.data.map((point) => point.x).toList(),
      <double>[2.5, 7.5],
      reason:
          'PlotlySchemaAdapter.ts:1876 plots each bar at the bin CENTRE, '
          '(x0 + x1) / 2 over [0, 5) and [5, 10).',
    );
    expect(
      chart.data.map((point) => point.xAxisCalloutData).toList(),
      <String>['[0 - 5)', '[5 - 10)'],
      reason:
          'PlotlySchemaAdapter.ts:1882 formats the callout as the half-open '
          'interval, which only the binning transformer produces.',
    );
    expect(
      chart.mode,
      'histogram',
      reason:
          'PlotlySchemaAdapter.ts:1893 injects the histogram render mode, so '
          'the chart drops the inner padding at vertical_bar_chart.dart:657.',
    );
    expect(
      tester.getSize(find.byType(FluentVerticalBarChart)).height,
      600,
      reason:
          'PlotlySchemaAdapter.ts:1892 is `input.layout?.height ?? 350`, and '
          'the transformer deliberately builds neither half (spec §2.2): both '
          "arrive as the cell's SizedBox, which exists only when "
          'kPlotlyDefaultCellHeight has an entry for the kind. Without the '
          'verticalBar entry the declared 600 is dropped on the floor and the '
          "chart falls back to the cartesian shell's own 350 "
          '(cartesian/cartesian_chart.dart:28) — which is why the default '
          'cannot be asserted here: it and the fallback are the same number.',
    );
  });

  testWidgets('a histogram carrying histfunc and histnorm reaches both through '
      'the widget', (tester) async {
    await pump(
      tester,
      FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: histogramFigure(histfunc: 'sum', histnorm: 'percent'),
        ),
      ),
    );
    final chart = tester.widget<FluentVerticalBarChart>(
      find.byType(FluentVerticalBarChart),
    );
    expect(
      chart.data.map((point) => point.y).toList(),
      <double>[75, 25],
      reason:
          'histfunc: sum reduces the bins to 30 and 10 '
          '(PlotlySchemaAdapter.ts:3446) and histnorm: percent scales each by '
          'the 40 total (:3467), so nothing but both arms firing in that order '
          'yields 75 and 25.',
    );
  });

  testWidgets(
    "a single-plot figure's selectedLegends dims the unselected areas",
    (tester) async {
      await pump(
        tester,
        FluentDeclarativeChart(
          chartSchema: FluentPlotlySchema(
            plotlySchema: areaFigure(),
            selectedLegends: const <String>['a'],
          ),
        ),
      );
      final delegate =
          tester
                  .widget<FluentCartesianChart>(
                    find.byType(FluentCartesianChart),
                  )
                  .delegate
              as FluentAreaChartDelegate;
      expect(
        delegate.selectedLegends,
        <String>['a'],
        reason:
            'DeclarativeChart.tsx:598-603 spreads interactiveCommonProps into '
            'EVERY non-annotation chart, so the single-plot path carries the '
            'selection too — it is not a multi-plot-only knob.',
      );
      // The parameter arriving is not the point; the marks changing is. Both
      // are asserted because the first localises a break in the wiring and the
      // second catches a chart that takes the value and ignores it.
      expect(
        <double>[
          delegate.fillOpacityFor('a'),
          delegate.fillOpacityFor('b'),
          delegate.fillOpacityFor('c'),
        ],
        <double>[0.7, 0.1, 0.1],
        reason:
            '_getOpacity (AreaChart.tsx:619-626): the highlighted legend keeps '
            '0.7 and every other series drops to 0.1.',
      );
      expect(
        tester
            .widget<FluentChartLegend>(find.byType(FluentChartLegend))
            .selectedLegends,
        <String>['a'],
        reason:
            'AreaChart.tsx:589 spreads legendProps over the legend row, so A’s '
            'swatch is filled and the rest are outlines.',
      );
    },
  );
}

/// Three stacked `tonexty` scatter traces — the shape of `DEFAULT_SCHEMAS[0]`
/// in the DeclarativeChart story, reduced to what the routing reads.
Map<String, Object?> areaFigure() => <String, Object?>{
  'data': <Object?>[
    for (final name in <String>['a', 'b', 'c'])
      <String, Object?>{
        'type': 'scatter',
        'mode': 'lines',
        'fill': 'tonexty',
        'name': name,
        'x': <Object?>[0, 1, 2],
        'y': <Object?>[1, 2, 3],
      },
  ],
  'layout': <String, Object?>{},
};
