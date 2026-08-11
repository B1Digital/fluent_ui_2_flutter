import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/declarative_chart.dart';
import 'package:fluent_2_web/src/charts/donut_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The degenerate-grid collapse (`DeclarativeChart.tsx:510-533`) and the
/// multi-plot title gate (`:545-546`, `:561`), both mounted rather than called:
/// the collapse is a private method on the state and only the rendered tree
/// proves it ran.
///
/// There is one captured DeclarativeChart story in Oracle B and it is none of
/// these figures, so every expectation below is hand-derived from the upstream
/// lines cited beside it.
void main() {
  /// 800 rather than the 400 a single 350-tall cell needs: the two figures that
  /// keep their title draw a 1x2 grid plus the title and the all-up legend, and
  /// a `Column` that overflows its box fails the test on the overflow, not on
  /// the assertion.
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: SizedBox(width: 700, height: 800, child: child)),
    ),
  );

  /// The two side-by-side domains `getGridProperties` needs in order to resolve
  /// a real 1x2 grid (`PlotlySchemaAdapter.ts:3663-3699`); without them the
  /// grid collapses to one cell and the figure stops being multi-plot.
  const sideBySideDomains = <String, Object?>{
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
  };

  const twoBarTraces = <Object?>[
    <String, Object?>{
      'type': 'bar',
      'xaxis': 'x',
      'x': <Object?>['a'],
      'y': <Object?>[1],
    },
    <String, Object?>{
      'type': 'bar',
      'xaxis': 'x2',
      'x': <Object?>['b'],
      'y': <Object?>[2],
    },
  ];

  testWidgets('two pies with no domains collapse to the LAST one', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'type': 'pie',
                'labels': <Object?>['first'],
                'values': <Object?>[1],
              },
              <String, Object?>{
                'type': 'pie',
                'labels': <Object?>['second'],
                'values': <Object?>[2],
              },
            ],
          },
        ),
      ),
    );
    final chart = tester.widget<FluentDonutChart>(
      find.byType(FluentDonutChart),
    );
    expect(
      chart.data.chartData?.single.legend,
      'second',
      reason:
          'DeclarativeChart.tsx:516-523 keeps the LAST group for a donut, '
          'matching plotly.',
    );
  });

  testWidgets('two bar groups with no domains collapse to the FIRST one', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{'data': twoBarTraces},
        ),
      ),
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsOneWidget,
      reason:
          'DeclarativeChart.tsx:524-530 keeps only the first group for every '
          'non-donut type.',
    );
  });

  testWidgets('after collapsing, the figure is no longer multi-plot', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': twoBarTraces,
            'layout': <String, Object?>{'title': 'collapsed'},
          },
        ),
      ),
    );
    expect(
      find.text('collapsed'),
      findsNothing,
      reason:
          'DeclarativeChart.tsx:532 forces isMultiPlot false, which suppresses '
          'both the title div at :561 and the all-up legend at :634.',
    );
  });

  testWidgets('a genuine multi-plot figure does render its title', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': twoBarTraces,
            'layout': <String, Object?>{'title': 'kept', ...sideBySideDomains},
          },
        ),
      ),
    );
    expect(
      find.text('kept'),
      findsOneWidget,
      reason: 'DeclarativeChart.tsx:561.',
    );
  });

  testWidgets('the title reads layout.title.text when the title is an object', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': twoBarTraces,
            'layout': <String, Object?>{
              'title': <String, Object?>{'text': 'object title'},
              ...sideBySideDomains,
            },
          },
        ),
      ),
    );
    expect(
      find.text('object title'),
      findsOneWidget,
      reason: 'DeclarativeChart.tsx:545-546.',
    );
  });
}
