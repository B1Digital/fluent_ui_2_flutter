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

  /// The single full-square axis pair that solves to a real one-by-one grid:
  /// `PlotlySchemaAdapter.ts:3774` and `:3807` both format `repeat(1, 1fr)`,
  /// which is the `SINGLE_REPEAT` at `:103` that `DeclarativeChart.tsx:513-514`
  /// collapses on. A layout with no axis keys at all does NOT reach this state
  /// — it keeps the `1fr` seeded at `:3654-3655`.
  const oneByOneDomains = <String, Object?>{
    'xaxis': <String, Object?>{
      'domain': <Object?>[0, 1],
      'anchor': 'y',
    },
    'yaxis': <String, Object?>{
      'domain': <Object?>[0, 1],
      'anchor': 'x',
    },
  };

  /// The two side-by-side domains `getGridProperties` needs in order to resolve
  /// a real 1x2 grid (`PlotlySchemaAdapter.ts:3663-3699`).
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

  testWidgets('two bar groups on a solved 1x1 collapse to the FIRST one', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': twoBarTraces,
            'layout': oneByOneDomains,
          },
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
            'layout': <String, Object?>{
              'title': 'collapsed',
              ...oneByOneDomains,
            },
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

  testWidgets('two bar groups with NO axis layout are not collapsed', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentDeclarativeChart(
        chartSchema: FluentPlotlySchema(
          plotlySchema: <String, Object?>{
            'data': twoBarTraces,
            'layout': <String, Object?>{'title': 'kept without axes'},
          },
        ),
      ),
    );
    expect(
      find.text('kept without axes'),
      findsOneWidget,
      reason:
          'Neither PlotlySchemaAdapter.ts:3762 nor :3793 runs for a layout '
          'with no xaxis/yaxis key, so both templates keep the `1fr` seeded '
          'at :3654-3655. `1fr` is not the SINGLE_REPEAT at :103, so '
          'DeclarativeChart.tsx:513-514 is false and :532 never forces '
          'isMultiPlot back off — the title at :561 survives.',
    );
    expect(
      find.byType(FluentVerticalStackedBarChart),
      findsNWidgets(2),
      reason:
          'Both groups are still rendered, each with the row 1 / column 1 '
          'DeclarativeChart.tsx:623-624 falls back to for a missing cell, '
          'which :162-165 turns into the same one-cell grid area for both.',
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
