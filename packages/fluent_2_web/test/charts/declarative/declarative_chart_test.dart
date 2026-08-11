import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/declarative_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
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
  Future<void> pump(WidgetTester tester, Widget child, {double height = 400}) =>
      tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: SizedBox(width: 700, height: height, child: child),
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
}
